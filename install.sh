#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Install givemesudo command
install -m 0755 "$SCRIPT_DIR/givemesudo.sh" /usr/local/bin/givemesudo

# Install systemd units
cp "$SCRIPT_DIR/givemesudo-cleanup.service" "$SCRIPT_DIR/givemesudo-cleanup.timer" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now givemesudo-cleanup.timer

echo "Timer installed and active."
systemctl list-timers givemesudo-cleanup.timer
