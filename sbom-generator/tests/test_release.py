import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("release", Path(__file__).parents[1] / "release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)

IMAGE = "ghcr.io/example/cnpg-sbom-generator"
REVISION = "a" * 40
REPOSITORY = "example/postgres-extensions-containers"
DIGEST = "sha256:" + "b" * 64


class ReleaseTests(unittest.TestCase):
    def test_only_explicit_missing_manifest_allows_build(self):
        ref = IMAGE + ":sha-" + REVISION
        error = subprocess.CalledProcessError(1, [], stderr=f"ERROR: {ref}: not found\n")
        with patch.object(release, "run", side_effect=error):
            self.assertIsNone(release.digest_for(ref, allow_missing=True))
            with self.assertRaises(subprocess.CalledProcessError):
                release.digest_for(ref)

    def test_registry_errors_fail_closed(self):
        for message in ("unauthorized", "denied", "429 Too Many Requests", "503 Service Unavailable",
                        "connection refused", "ERROR: some-other-image: not found"):
            with self.subTest(message=message):
                error = subprocess.CalledProcessError(1, [], stderr=message)
                with patch.object(release, "run", side_effect=error):
                    with self.assertRaises(subprocess.CalledProcessError):
                        release.digest_for(IMAGE, allow_missing=True)

    def test_rejects_invalid_digest(self):
        with patch.object(release, "run", return_value="latest"):
            with self.assertRaises(ValueError):
                release.digest_for(IMAGE)

    def configs(self):
        return {f"linux/{arch}": {
            "os": "linux", "architecture": arch,
            "config": {"Labels": {
                "org.opencontainers.image.revision": REVISION,
                "org.opencontainers.image.source": f"https://github.com/{REPOSITORY}",
            }},
        } for arch in ("amd64", "arm64")}

    def test_verifies_both_platforms_and_labels(self):
        with patch.object(release, "run", return_value=json.dumps(self.configs())):
            release.verify_image(IMAGE, DIGEST, REVISION, REPOSITORY)

    def test_rejects_wrong_platform_or_source(self):
        for field in ("missing-platform", "org.opencontainers.image.revision", "org.opencontainers.image.source"):
            configs = self.configs()
            if field == "missing-platform":
                del configs["linux/arm64"]
            else:
                configs["linux/arm64"]["config"]["Labels"][field] = "wrong"
            with self.subTest(field=field), patch.object(release, "run", return_value=json.dumps(configs)):
                with self.assertRaises(ValueError):
                    release.verify_image(IMAGE, DIGEST, REVISION, REPOSITORY)

    def test_rerun_reuses_commit_digest_without_build(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(release, "digest_for", return_value=DIGEST), \
                 patch.object(release, "verify_image") as verify, \
                 patch.object(release.subprocess, "run") as command:
                result = release.build(IMAGE, REVISION, REPOSITORY, Path(directory))
                self.assertEqual(result, DIGEST)
                command.assert_not_called()
                verify.assert_called_once_with(IMAGE, DIGEST, REVISION, REPOSITORY)
                self.assertEqual((Path(directory) / "digest").read_text().strip(), DIGEST)

    def test_new_commit_uses_digest_from_build_metadata(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)

            def build_command(*args, **kwargs):
                (output / "build.json").write_text(json.dumps({"containerimage.digest": DIGEST}))

            with patch.object(release, "digest_for", side_effect=[None, DIGEST]), \
                 patch.object(release, "verify_image") as verify, \
                 patch.object(release.subprocess, "run", side_effect=build_command) as command:
                self.assertEqual(release.build(IMAGE, REVISION, REPOSITORY, output), DIGEST)
                self.assertIn(IMAGE + ":sha-" + REVISION, command.call_args.args[0])
                self.assertNotIn(IMAGE + ":latest", command.call_args.args[0])
                verify.assert_called_once_with(IMAGE, DIGEST, REVISION, REPOSITORY)

    def test_failed_build_leaves_no_digest_for_promotion(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            with patch.object(release, "digest_for", return_value=None), \
                 patch.object(release.subprocess, "run", side_effect=subprocess.CalledProcessError(1, [])):
                with self.assertRaises(subprocess.CalledProcessError):
                    release.build(IMAGE, REVISION, REPOSITORY, output)
                self.assertFalse((output / "digest").exists())

    def test_stale_main_does_not_promote(self):
        with patch.object(release, "digest_for", return_value=DIGEST), \
             patch.object(release, "run", return_value="c" * 40), \
             patch.object(release.subprocess, "run") as command:
            self.assertFalse(release.promote(IMAGE, DIGEST, REVISION, REPOSITORY, "latest"))
            command.assert_not_called()

    def test_test_alias_does_not_require_main_head(self):
        with patch.object(release, "digest_for", return_value=DIGEST), \
             patch.object(release, "run") as read, \
             patch.object(release.subprocess, "run") as command:
            self.assertTrue(release.promote(IMAGE, DIGEST, REVISION, REPOSITORY, "test"))
            read.assert_not_called()
            self.assertIn(IMAGE + ":test", command.call_args.args[0])
            self.assertEqual(command.call_args.args[0][-1], IMAGE + "@" + DIGEST)

    def test_current_main_promotes_latest(self):
        with patch.object(release, "digest_for", return_value=DIGEST), \
             patch.object(release, "run", return_value=REVISION), \
             patch.object(release.subprocess, "run") as command:
            self.assertTrue(release.promote(IMAGE, DIGEST, REVISION, REPOSITORY, "latest"))
            self.assertIn(IMAGE + ":latest", command.call_args.args[0])

    def test_changed_commit_tag_blocks_promotion(self):
        with patch.object(release, "digest_for", return_value="sha256:" + "c" * 64), \
             patch.object(release.subprocess, "run") as command:
            with self.assertRaises(ValueError):
                release.promote(IMAGE, DIGEST, REVISION, REPOSITORY, "test")
            command.assert_not_called()

    def test_checks_alias_digest_after_promotion(self):
        with patch.object(release, "digest_for", side_effect=[DIGEST, "sha256:" + "c" * 64]), \
             patch.object(release.subprocess, "run"):
            with self.assertRaises(ValueError):
                release.promote(IMAGE, DIGEST, REVISION, REPOSITORY, "test")


if __name__ == "__main__":
    unittest.main()
