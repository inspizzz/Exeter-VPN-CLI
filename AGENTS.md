# AGENTS.md

Instructions for AI coding agents (Claude Code, Codex, Gemini CLI, Copilot, Cursor, …) working in this repo.
Humans: see [README.md](README.md).

## What this repo is

A guide and a single-file bash CLI (`bin/exeter-vpn`) for connecting Fedora Linux to the
University of Exeter VPN (`remote.exeter.ac.uk`, HPE Aruba VIA 4.7.6). There's no build step and no
dependencies beyond `bash`, `curl`, `iproute2`, `systemd-resolved`, and the proprietary `via` RPM.

```
bin/exeter-vpn              the CLI (all logic lives here)
install.sh                  installs the CLI to ~/.local/bin + bash completion
completions/exeter-vpn.bash bash completion
docs/how-it-works.md        gateway login flow, tunnel details, log locations
docs/troubleshooting.md     symptom -> fix
.claude/skills/             Claude Code skills (setup, troubleshoot)
private/                    git-ignored; the maintainer's personal notes - never read into commits
```

## Facts you must not get wrong

1. **"VIA Next/New Pin" means wrong credentials, not an MFA code request.** The gateway returns this
   RADIUS-challenge page for *any* wrong password. Check the username and password before touching MFA settings.
   (A whole debugging day was lost to this.)
2. **One VIA client at a time.** `via-ui` (GUI) and `via-cli` can't run together, and **starting the GUI
   force-disconnects an existing tunnel.** "Connects then dies" usually means the GUI started.
3. MFA on the VPN supports **Authenticator push or phone call only**. There is no number matching (RADIUS
   can't display it).
4. The VPN works **only from off campus**, not on eduroam.
5. The VIA **keystore password** is chosen by the user on first `-k` use. It's separate from the University password.
6. Username: the full `ab123@exeter.ac.uk` worked. Exeter's docs say the bare username. Don't claim either is required.
7. The service log `/usr/share/via/logs/app-vpn.log` contains binary bytes, so always use `grep -a`.
   `Cann't possible to send crypted frame -8807` spam is harmless if traffic flows.
8. MTU: VIA drops *outgoing* packets above a cap a few bytes below the MTU it connected with
   (`<via_mtu>` 1250 gives 1246; 1240 gives 1230; 1220 gives 1214). Symptom: downloads fine, but uploads, large API
   requests and post-quantum TLS hellos hang. Raising the interface MTU later doesn't raise the cap, and
   starting lower lowers it, so never "lower until it works" blindly or copy someone's number (e.g. 1400).
   `connect` measures the cap, sets the interface to it, and starts VIA there next time. Starting at 1246
   gives a cap of exactly 1246 (verified), so later connects need no sudo. Test over IPv4 (`curl -4`): IPv6 bypasses the
   tunnel, so a working browser proves nothing.
9. VIA may not register the pushed campus DNS servers with systemd-resolved (`status` shows "DNS none
   set"). Public names still resolve via the home router, but campus-only names don't. `exeter-vpn dns` fixes it.

## Safety rules

- **Never commit or print credentials**: University password, keystore password, `~/.via/userpass`,
  `~/.via/vpn_service_config.xml` (holds the password in plain text), `profile.xml`, cookies
  (`VIA_SESSION`, `CPnextpin`), HAR files, or anything in `private/`. Before committing, grep the diff for
  usernames such as `ab123`, `@exeter.ac.uk` addresses other than examples, `state=`, and `VIA_SESSION=`.
- **Ask before** `exeter-vpn connect|disconnect|login|install|mtu N|dns`, `via-cli vpn …`, `pkill via-ui`,
  or `sudo` anything. These change the user's network (a full tunnel reroutes *all* traffic, including
  your own API calls), need the user's phone for MFA, or need a password only the user should type.
- Read-only commands are always fine: `exeter-vpn status|doctor|logs|mtu|config`, `ip`, `resolvectl status`,
  reading logs.
- Never type the user's University password into a web form or terminal for them. Have them run the
  interactive command themselves in their own terminal and paste the output back (sudo can't prompt
  without a TTY, so Claude Code's `!` prefix doesn't work for these).
- Repeated failed MFA attempts can lock the account's MFA temporarily. Stop after 2–3 failures and
  re-check credentials.
- Don't vendor or upload the VIA installer/RPM. It's proprietary; link to exeter.ac.uk instead.

## Working on the CLI

- Single file, `set -euo pipefail`, no external dependencies. Keep it that way.
- Style: small `cmd_<name>` functions; UI helpers `step ok warn bad hint die ask spin`; colours only on a TTY
  and honour `NO_COLOR`. Messages say what happened *and* what to do next.
- Secrets: read with `read -s`, pass to curl through a mode-600 temp file (`passwd@file`), never as argv.
- Network calls to the gateway go through `http()`, which retries only when the TCP connect hangs. Don't
  retry once a request was sent: a resend triggers a second MFA push.
- Add new subcommands to `main()`, `cmd_help()`, `completions/exeter-vpn.bash`, and the README.

## Testing

```bash
bash -n bin/exeter-vpn install.sh completions/exeter-vpn.bash   # syntax
shellcheck bin/exeter-vpn                                        # if installed
bin/exeter-vpn help; bin/exeter-vpn doctor; bin/exeter-vpn status   # safe, read-only
```

`login`/`connect` need real credentials and a phone, so ask the user to run them. There's no CI. Report
honestly which commands you actually ran.
