#!/usr/bin/env bash
set -euo pipefail

readonly USER="${SUDO_USER:-$(id -un)}"
readonly TARGET="/etc/sudoers.d/givemesudo_${USER}"

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Install the sudoers drop-in with inline content
cat > "$TARGET" <<EOF
${USER} ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 "$TARGET"

# Validate syntax before proceeding
if ! visudo -cf "$TARGET"; then
  rm -f "$TARGET"
  echo "Sudoers syntax check failed. File removed." >&2
  exit 1
fi

echo "sudoers file installed at $TARGET"
echo "Will be cleaned up by givemesudo-cleanup.timer (after 1 hour)."
