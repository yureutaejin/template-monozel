#!/usr/bin/env -S bash -euo pipefail
# Build a target sysroot and export only the directories needed by a compiler.

platform="${1:-}"
case "$platform" in
  linux/arm64 | linux/amd64) ;;
  *)
    echo "usage: $0 linux/arm64|linux/amd64" >&2
    exit 2
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
arch="${platform#linux/}"
image="local/sysroot:$arch"
container="sysroot-export-$arch-$$"
output_dir="$script_dir/out"
archive="$output_dir/sysroot-$arch.tar.gz"

cleanup() {
  if [[ -n "${mount_dir:-}" ]]; then
    sudo buildah umount "$container" >/dev/null 2>&1 || true
  fi
  sudo buildah rm "$container" >/dev/null 2>&1 || true
}
trap cleanup EXIT

mkdir -p "$output_dir"

sudo buildah build \
  --no-cache \
  --platform "$platform" \
  --tag "$image" \
  --file "$script_dir/Containerfile" \
  "$script_dir"

sudo buildah from --name "$container" "$image" >/dev/null
mount_dir="$(sudo buildah mount "$container")"

paths=(lib usr/include usr/lib usr/share/sysroot-manifest)
[[ -e "$mount_dir/lib64" ]] && paths+=(lib64)
[[ -e "$mount_dir/usr/lib64" ]] && paths+=(usr/lib64)

sudo tar --create --gzip --file "$archive" \
  --directory "$mount_dir" \
  "${paths[@]}"
sudo chown "$(id -u):$(id -g)" "$archive"
sha256sum "$archive" > "$archive.sha256"

printf 'wrote %s\n' "$archive"
