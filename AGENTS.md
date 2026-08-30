# givemesudo

Grants the caller passwordless sudo for ~1 hour via a per-user sudoers drop-in,
then a systemd timer reaps expired drop-ins. No build, no tests — it's three
small bash files plus two systemd units.

## Files

- `givemesudo.sh` — the command (installed to `/usr/local/bin/givemesudo`).
  Root-only. Writes `/etc/sudoers.d/givemesudo_${SUDO_USER}` as `NOPASSWD: ALL`,
  `chmod 0440`, validates with `visudo -cf`, deletes the file if validation fails.
- `givemesudo-cleanup.timer` / `.service` — every 5 min, `find`s
  `/etc/sudoers.d/givemesudo_*` older than 60 min and deletes them. The 60-min
  window is what defines the grant's TTL.
- `install.sh` — root-only. Installs the command and units, `daemon-reload`s,
  `enable --now` the timer, then lists it.

## Constraints

- The sudoers drop-in is written *before* `visudo -cf` runs; keep that
  order-of-operations (and the delete-on-failure path) intact in any edit.
- Keep the drop-in filename prefix `givemesudo_` in sync with the cleanup
  `find -name` pattern — renaming one without the other silently breaks cleanup.
- The three project files must stay identical to the installed copies
  (`/usr/local/bin/givemesudo`, `/etc/systemd/system/givemesudo-cleanup.{service,timer}`);
  `install.sh` is the update path (verify with `diff`).
- All bash uses `set -euo pipefail`; keep new scripts consistent.
- Not yet a git repo — when initializing, follow the global git-init workflow
  (`.gitignore` + single "FIRST" commit).
