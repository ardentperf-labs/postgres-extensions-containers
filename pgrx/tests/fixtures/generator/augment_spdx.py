def augment_spdx(document, context):
    assert context.api_version == 1, 'unsupported hook API'
    assert context.platform == 'linux/amd64', 'unexpected platform'
    assert context.builder_document['spdxVersion'].startswith('SPDX-'), 'not builder SPDX'
    assert any(p['name'] == 'cnpg-hook-builder-only' for p in context.builder_document['packages']), 'builder evidence missing'
    assert not any(p['name'] == 'cnpg-hook-builder-only' for p in document['packages']), 'builder package leaked'
    assert (context.builder_path / 'usr/share/probe/payload').read_bytes() == (context.final_path / 'payload').read_bytes(), 'mount mismatch'
    assert document['files'][0]['checksums'], 'missing inventory'
    document['comment'] = 'cnpg-pgrx-hook-api-v1-native-compatibility-passed'
    return document
