# givemesudo

Grant yourself passwordless sudo for exactly one hour — without touching your real sudoers policy.

`givemesudo` writes a temporary per-user drop-in to `/etc/sudoers.d/` giving the
caller `NOPASSWD: ALL`. A systemd timer sweeps `/etc/sudoers.d/` every five
minutes and deletes any drop-in older than 60 minutes, so the grant expires on
its own. No config, no daemon, no state to manage: run it, get root, and it's
gone within the hour.

## Install

Requires root (systemd, `visudo`).

```sh
sudo ./install.sh
```

This installs:

- `givemesudo` → `/usr/local/bin/givemesudo`
- `givemesudo-cleanup.{service,timer}` → `/etc/systemd/system/` (enabled and started)

## Usage

Run it as your normal user; it elevates once (via your existing sudo setup)
and then your own sudo is passwordless for an hour:

```sh
sudo givemesudo
# sudoers file installed at /etc/sudoers.d/givemesudo_<you>
# Will be cleaned up by givemesudo-cleanup.timer (after 1 hour).

sudo whoami          # root, no password prompt for ~1 hour
```

Re-running `givemesudo` refreshes the drop-in, which effectively extends the
window — the timer only deletes files untouched for 60 minutes.

## How cleanup works

| Unit | What it does |
|---|---|
| `givemesudo-cleanup.timer` | Fires every 5 minutes (`OnCalendar=*:0/5`) |
| `givemesudo-cleanup.service` | `find /etc/sudoers.d -maxdepth 1 -name 'givemesudo_*' -mmin +60 -delete` |

Only files matching the `givemesudo_*` prefix are ever touched — your existing
sudoers drop-ins are left alone.

## Safety notes

- The drop-in is `chmod 0440` and validated with `visudo -cf` after being
  written; if validation fails, the file is deleted and the script exits
  non-zero.
- While the grant is active, *any* path to this user's session is full
  passwordless root. Use it on machines where that's acceptable, and assume
  it expires within ~65 minutes (60 min + up to 5 min sweep delay).
- To revoke early: `sudo rm /etc/sudoers.d/givemesudo_$USER`.

## License

[Apache License 2.0](LICENSE)

## Files

- `givemesudo.sh` — the command
- `givemesudo-cleanup.timer` / `givemesudo-cleanup.service` — the expiry sweep
- `install.sh` — installs and updates everything (re-run after any change)
