#!/usr/bin/env bash
set -eux

# Based on the system-library staging in CloudNativePG's PostGIS image:
# https://github.com/cloudnative-pg/postgres-extensions-containers/blob/main/postgis/Dockerfile
# Optional --exclude-dir DIR skips libraries already bundled in another tree.

exclude_dir=
if [ "${1:-}" = "--exclude-dir" ]; then
	if [ "$#" -lt 3 ]; then
		echo "ERROR: --exclude-dir requires a directory and at least one library input." >&2
		exit 1
	fi
	if ! exclude_dir=$(readlink -f "$2") || [ ! -d "$exclude_dir" ]; then
		echo "ERROR: Exclusion directory does not exist or cannot be resolved: $2" >&2
		exit 1
	fi
	shift 2
fi

if [ ! -r /tmp/base-image-libs.out ] || [ ! -s /tmp/base-image-libs.out ]; then
	echo "ERROR: Base image library capture is missing or empty. Run capture_base_image_libs.sh before installing extension packages, in the same builder stage." >&2
	exit 1
fi

# Get libraries
ldd "$@" | awk '{print $3}' | grep '^/' | sort | uniq > /tmp/all-deps.out
if [ -n "$exclude_dir" ]; then
	: > /tmp/filtered-deps.out
	while read -r lib; do
		# Resolve directory aliases without following the library symlink itself.
		library_path="$(readlink -f "$(dirname "$lib")")/$(basename "$lib")"
		case "$library_path" in
			"$exclude_dir"|"${exclude_dir%/}/"*) continue ;;
		esac
		printf '%s\n' "$lib" >> /tmp/filtered-deps.out
	done < /tmp/all-deps.out
	mv /tmp/filtered-deps.out /tmp/all-deps.out
fi
# Extract all the libs that aren't already part of the base image
comm -13 /tmp/base-image-libs.out /tmp/all-deps.out > /tmp/libraries.out

if [ ! -s /tmp/libraries.out ]; then
	echo "ERROR: No additional system libraries detected. Install extension packages between capture_base_image_libs.sh and stage_system_libs.sh, and pass the extension's shared libraries to stage_system_libs.sh." >&2
	exit 1
fi

mkdir -p /system /licenses
while read -r lib; do
	resolved=$(readlink -f "$lib")
	dir=$(dirname "$lib")
	base=$(basename "$lib")
	# Copy the real file
	cp -a "$resolved" /system/
	# Reconstruct all its symlinks
	for file in "$dir"/"${base%.so*}.so"*; do
		[ -e "$file" ] || continue
		# If it's a symlink and it resolves to the same real file, we reconstruct it
		if [ -L "$file" ] && [ "$(readlink -f "$file")" = "$resolved" ]; then
			# A same-name alias would replace the copied library with a self-link.
			[ "$(basename "$file")" = "$(basename "$resolved")" ] && continue
			ln -sf "$(basename "$resolved")" "/system/$(basename "$file")"
		fi
	done
done < /tmp/libraries.out

# Preserve aliases supplied as input, such as libmysqlclient.so. ldd may report
# only the resolved soname, so the dependency loop cannot infer this alias.
for input_file in "$@"; do
	if [ -L "$input_file" ]; then
		if [ -n "$exclude_dir" ]; then
			input_path="$(readlink -f "$(dirname "$input_file")")/$(basename "$input_file")"
			case "$input_path" in
				"$exclude_dir"|"${exclude_dir%/}/"*) continue ;;
			esac
		fi
		resolved=$(readlink -f "$input_file")
		[ "$(basename "$input_file")" = "$(basename "$resolved")" ] && continue
		ln -sf "$(basename "$resolved")" "/system/$(basename "$input_file")"
	fi
done

# Get licenses
for lib in $(find /system -maxdepth 1 -type f -name '*.so*'); do
	# Get the name of the pkg that installed the library
	pkg=$(dpkg -S "$(basename "$lib")" | grep -v "diversion by" | awk -F: '/:/{print $1; exit}')
	[ -z "$pkg" ] && continue
	mkdir -p "/licenses/$pkg" && cp -a "/usr/share/doc/$pkg/copyright" "/licenses/$pkg/copyright"
done
