# Exeter VPN CLI

`exeter-vpn` is a command-line tool for the **University of Exeter VPN** (`remote.exeter.ac.uk`, Aruba VIA)
on Linux. It installs the official client, signs you in with MFA, and connects, fixing the Linux-specific
problems (MTU, DNS, the GUI dropping the tunnel) along the way.

> Unofficial and not affiliated with the University. For account or MFA problems, contact Exeter IT
> (sid@exeter.ac.uk).

```text
$ exeter-vpn status

  Exeter VPN  remote.exeter.ac.uk

  Tunnel         ● connected
  Address        10.46.x.x
  Interface      via_vpn, MTU 1246
  Routing        full tunnel (all traffic), 34 routes
  DNS            144.173.119.22 144.173.119.23
  Reachability   ✔ campus DNS answers ping
  Name lookup    ✔ names resolve
```

## Requirements

- Fedora / RHEL or Ubuntu / Debian (x86_64), with `sudo`. See [Supported distros](#supported-distros).
- **Off campus, not on eduroam.** The VPN refuses connections from inside the University network.
- Microsoft **Authenticator (notification)** or **Phone (call)** as your sign-in method, set at
  <https://mysignins.microsoft.com/security-info>. The VPN can't show number matching, so you just approve.

## Quick start

```bash
git clone https://github.com/inspizzz/Exeter-VPN-CLI.git
cd Exeter-VPN-CLI
./install.sh            # puts exeter-vpn in ~/.local/bin, with bash completion

exeter-vpn install      # installs the official VIA client from exeter.ac.uk and Exeter's root CA
exeter-vpn login        # University password + approve on your phone; downloads your VPN profile
exeter-vpn connect
```

After that, day to day it's just `exeter-vpn connect` and `exeter-vpn disconnect`. Run `login` again after
a password change or if the profile stops working.

Two passwords come up:

- **Your University password**, for `login` and the first `connect`. `exeter-vpn` never stores it.
- **A VIA keystore password** that you make up during `install`. It's separate from your University password.
  `exeter-vpn` offers to keep it in your desktop keyring so you aren't asked again.

## Commands

| Command | What it does |
|---|---|
| `install` | Download and install the VIA client, start its service, import Exeter's root CA, offer to disable the GUI autostart |
| `login [--pin]` | Sign in (password + phone approval), then fetch and load your VPN profile |
| `connect` (`up`) | Bring the tunnel up, check the largest packet that gets through, and fix the MTU if needed |
| `disconnect` (`down`) | Take the tunnel down |
| `status` | Address, routes, DNS and reachability at a glance |
| `doctor` | Check the install, service, network, profile and file permissions, and say what to fix |
| `logs [-f] [-n N]` | Show (or follow) the useful part of the VPN service log |
| `mtu [probe\|N\|reset]` | Show, re-measure, set or forget the MTU remembered for this network |
| `dns` | Point DNS at the campus servers, when campus names don't resolve |
| `gui` | Open the VIA GUI with a fix for invisible text on KDE |
| `config [user X]` | Show or set your username |
| `forget-keystore` | Remove the keystore password from your keyring |
| `clean` | Remove VIA temp/debug files and the download cache |

Environment variables: `EXETER_USER` (username), `EXETER_VPN_PASSFILE` (read the University password from a
mode-600 file), `EXETER_VPN_KEYSTORE` (keystore password), `NO_COLOR`.

## If something doesn't work

Start with `exeter-vpn doctor`. The common causes:

- **Connects, then drops:** the VIA GUI started (it kills existing tunnels). Use either the GUI or the CLI,
  not both.
- **Uploads or some apps hang while browsing works:** MTU. `connect` handles this automatically;
  `exeter-vpn mtu probe` re-checks. Test with `curl -4`, because IPv6 traffic bypasses the tunnel.
- **Campus names don't resolve:** `exeter-vpn dns`.
- **Gateway doesn't answer:** you're probably on eduroam or a campus network.

More in [docs/troubleshooting.md](docs/troubleshooting.md). How it all works: [docs/how-it-works.md](docs/how-it-works.md).
Installing the client by hand: [docs/manual-install.md](docs/manual-install.md).

## Security

- VIA itself saves your University password in plain text in `~/.via/vpn_service_config.xml`, readable by
  other users. `exeter-vpn doctor` checks for this; fix it with `sudo chmod 600 ~/.via/vpn_service_config.xml`.
- `exeter-vpn` never stores your University password, and passes both passwords to VIA through mode-600 temp
  files rather than the command line.

## Supported distros

| Distro | Install | Login | Connect | Tested |
|---|---|---|---|---|
| Fedora 43 (KDE Plasma 6) | ✅ | ✅ | ✅ | real machine, October 2026 |
| Ubuntu 24.04 LTS | ✅ | ❔ | ❔ | install only, in a container |
| Debian 13 (trixie) | ✅ | ❔ | ❔ | install only, in a container |

✅ verified, ❔ not tested yet. All with VIA 4.7.6. Other Fedora/RHEL and Ubuntu/Debian releases will
probably work. If you try one, please open an issue with `exeter-vpn doctor` output (remove your Wi-Fi name
and addresses first).

## For AI coding agents

[AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md) and the Claude Code skills in [.claude/skills/](.claude/skills/)
let an agent walk you through setup or troubleshooting. Open the repo in Claude Code and ask *"set up the
Exeter VPN"* or *"my Exeter VPN is broken"*.

## Licence

MIT, see [LICENSE](LICENSE). The VIA client is proprietary (HPE Aruba) and is downloaded from the
University's website, not redistributed here.
