# givemesudo

Give yourself — or your agent — full root for one hour, and let it expire by itself.

Every "I need root for a bit" moment pushes you toward a permanent change:
`timestamp_timeout` in sudoers, a `NOPASSWD` line, a sudo-group membership.
`givemesudo` makes it temporary instead. It writes a per-user drop-in to
`/etc/sudoers.d/` granting the caller `NOPASSWD: ALL`, and a systemd timer
deletes it 60 minutes later. No config to revert, no state to track: run it,
get root, and if you forget about it, it forgets itself.

## Why not just use sudo's `timestamp_timeout`?

Because a longer timeout doesn't do what you actually want:

- **Prompt vs. permission.** `timestamp_timeout` only suppresses the password
  prompt — every command is still gated by your real policy. If your sudoers
  doesn't allow it, more patience won't. `givemesudo` temporarily removes the
  gate entirely.
- **State vs. decision.** A timeout change is a permanent, system-wide config
  edit that applies to everyone until you remember to revert it. The drop-in is
  a visible file that deletes itself — the grant can't outlive the file.
- **You vs. everything.** The timeout only helps *you*, at a terminal, while
  interactive. With an active grant, every subprocess of your user — scripts,
  daemons, tmux sessions, `curl | sudo bash` installers, headless flows — can
  sudo any command without a prompt or per-command allowlists.

## Use cases

**Give an agent harness time-boxed root.** Coding agents (Claude Code, Pi,
…) constantly hit steps that need root. The alternatives are babysitting every
elevation, or a standing `NOPASSWD` in sudoers — full root, forever, for a
process that runs arbitrary model output. `givemesudo` turns that into a
deliberate, bounded decision:

```sh
sudo givemesudo     # "this session gets root for the next hour"
claude              # its bash tool can sudo any command, ~1 hour, then it's gone
```

**One-off root work.** Messing with system state — services, sysctls,
package installs — without leaving any trace in your sudoers afterwards.

**Scripts and installers.** Anything that shells out to sudo internally works
non-interactively for the window, without pre-allowlisting each command.

## Install

Requires root (systemd, `visudo`).

```sh
git clone https://github.com/raykrueger/givemesudo.git
cd givemesudo
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
  passwordless root — that includes anything that can execute code as your
  user (agents, editors, downloaded scripts). Use it on machines where that's
  acceptable, and assume it expires within ~65 minutes (60 min + up to 5 min
  sweep delay).
- To revoke early: `sudo rm /etc/sudoers.d/givemesudo_$USER`.

## License

[Apache License 2.0](LICENSE)

## Files

- `givemesudo.sh` — the command
- `givemesudo-cleanup.timer` / `givemesudo-cleanup.service` — the expiry sweep
- `install.sh` — installs and updates everything (re-run after any change)
