#!/usr/bin/env -S bash -euo pipefail
# Register amd64 user-mode emulation on the Docker host for local sysroot work.
#
# This is intentionally not a devcontainer lifecycle hook: binfmt_misc is host
# kernel state shared by other containers and remains after this helper exits.

readonly BINFMT_IMAGE="tonistiigi/binfmt@sha256:400a4873b838d1b89194d982c45e5fb3cda4593fbfd7e08a02e76b03b21166f0"
readonly ENTRY="/proc/sys/fs/binfmt_misc/qemu-x86_64"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker CLI is required to register binfmt on the Docker host" >&2
  exit 1
fi

# A valid existing registration has an enabled fixed interpreter. In a
# non-privileged environment /proc may not reveal host binfmt_misc; installing
# again is safe and lets the privileged Docker helper make the authoritative
# decision.
if [[ -r "${ENTRY}" ]] \
  && grep -qx 'enabled' "${ENTRY}" \
  && grep -Eq '^flags:.*F' "${ENTRY}"; then
  echo "amd64 binfmt_misc emulation is already enabled"
  exit 0
fi

cat >&2 <<'EOF'
Registering amd64 binfmt_misc emulation on the Docker host.
This changes host-kernel state and may affect other containers. It is required
only to execute linux/amd64 Containerfile RUN steps from a non-amd64 host.
EOF

docker run --privileged --rm "${BINFMT_IMAGE}" --install amd64
