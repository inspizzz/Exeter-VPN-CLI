# Exeter VPN on Fedora

Connect to the **University of Exeter VPN** (`remote.exeter.ac.uk`, Aruba VIA) from **Fedora Linux**,
with a small command-line tool, `exeter-vpn`, that wraps the steps that are fiddly on Linux.

> Unofficial and not affiliated with the University. For account or MFA problems, contact
> Exeter IT (sid@exeter.ac.uk). Tested on Fedora 43 (KDE Plasma 6) with VIA 4.7.6, October 2026.

```text
$ exeter-vpn status

  Exeter VPN  remote.exeter.ac.uk

  Tunnel         ● connected
  Address        10.46.x.x
  Interface      via_vpn, MTU 1250
  Routing        full tunnel (all traffic), 34 routes
  DNS            144.173.119.22 144.173.119.23
  Reachability   ✔ campus DNS answers ping
  Name lookup    ✔ names resolve
```

## Before you start

- You must be **off campus and not on eduroam**. The VPN refuses connections from inside the University network.
- Your Microsoft account needs **Microsoft Authenticator (notification)** or **Phone (call)** as its
  sign-in method. Check this at <https://mysignins.microsoft.com/security-info>.
- You need `sudo` on the machine.

## Quick start

```bash
git clone https://github.com/inspizzz/Exeter-VPN-Fedora.git
cd Exeter-VPN-Fedora
./install.sh            # puts `exeter-vpn` in ~/.local/bin (+ bash completion)

exeter-vpn install      # downloads the official VIA client from exeter.ac.uk, installs it, imports the CA
exeter-vpn login        # password + approve on your phone -> downloads and loads your VPN profile
exeter-vpn connect      # brings the tunnel up
exeter-vpn status
```

After the first time, you only need `exeter-vpn connect` and `exeter-vpn disconnect`. Run `login` again if
the profile stops working, for example after a password change.

Run `exeter-vpn doctor` whenever something seems wrong.

## What `exeter-vpn install` does (manual equivalent)

The University publishes the Linux client at <https://www.exeter.ac.uk/departments/it/help/howdoi/vpn/>.
The "RHEL/CentOS" download is a **self-extracting installer** rather than a plain RPM, but it has an
`extract` mode that produces one:

```bash
base=https://www.exeter.ac.uk/v8media/universityofexeter/it/documents/networks/vpn
curl -LO $base/via-4.7.6.2601123-rpm.x86_64_bin
curl -LO $base/rootca.pem
chmod +x via-4.7.6.2601123-rpm.x86_64_bin
./via-4.7.6.2601123-rpm.x86_64_bin extract via.rpm   # needs only dbus + libtdb
sudo dnf install ./via.rpm
sudo systemctl enable --now via-vpn

via-cli session start
via-cli -k '<choose-a-keystore-password>' cert import --CA --user rootca.pem
```

**The keystore password is one you invent.** The first time you pass `-k`, VIA uses that value as its local
keystore password, and every later `via-cli` command needs it. Don't reuse your University password.

The package also installs `/etc/xdg/autostart/via-auto.desktop`, which starts the VIA GUI at every login.
`exeter-vpn install` offers to disable this for your user (see the **one-client rule** below).

## Signing in, and what MFA looks like

`exeter-vpn login` signs in to the gateway's web login. You'll get a **Microsoft Authenticator
notification** (or a phone call, where you press `#`). Approve it, and the tool downloads your personal VPN
profile and loads it into VIA.

- **Username:** the **full address (`ab123@exeter.ac.uk`) worked reliably for us.** Exeter's own guide says to
  use the bare username, so try that too if you prefer.
- You won't see the two-digit number-matching prompt you get in a browser. The VPN uses an older
  protocol (RADIUS) that can't show a number, so you get a plain approve request.

### ⚠️ The "VIA Next/New Pin" trap

If the gateway answers with a page titled **"VIA Next/New Pin"** (a single code box),
**your username or password is almost certainly wrong.** The gateway returns this page for *any*
wrong password. It is not a real request for an MFA code. We lost a day chasing MFA settings
because a saved password had a one-character typo. `exeter-vpn login` detects this page and tells you.

## The one-client rule

Only **one** VIA client may run at a time: the GUI (`via-ui`) **or** the CLI.

- The CLI refuses to work while the GUI is open (`Failed to connect - another client … is running`).
- **Starting the GUI disconnects an existing tunnel** and then reconnects. This looks like "it connected and
  then killed itself".

Pick one. `exeter-vpn` offers to close the GUI when needed.

## Tips

| Problem | Fix |
|---|---|
| GUI text boxes are blank or invisible (KDE Plasma 6) | `exeter-vpn gui`, or `QT_QPA_PLATFORMTHEME=generic QT_STYLE_OVERRIDE=Fusion via-ui`. Permanent fix: install the Qt5 Breeze style (`sudo dnf install plasma-breeze-qt5`) |
| Connected, but web pages or SSH hang while small things like ping work | MTU. VIA usually sets 1250 itself. Check with `exeter-vpn mtu probe`, set with `exeter-vpn mtu 1300` (or lower) |
| `*.ex.ac.uk` names don't resolve | `exeter-vpn dns`: Exeter's documented workaround, `resolvectl domain via_vpn ex.ac.uk '~.'` |
| Requests to the gateway hang now and then | The path to `remote.exeter.ac.uk` is lossy, so retry. The tool retries automatically |
| Gateway won't respond at all | Are you on eduroam or a campus network? Use a hotspot or home Wi-Fi |

**MTU tip from a colleague:** the VPN "stayed in an endless loop and never connected, or connected but no
data was exchanged" until the MTU was lowered. On our machine VIA already chose a safe MTU (1250), but if you
see those symptoms, MTU is the first thing to try.

More detail: [docs/troubleshooting.md](docs/troubleshooting.md) and [docs/how-it-works.md](docs/how-it-works.md).

## Security notes

- VIA stores your University password **in plain text** in `~/.via/vpn_service_config.xml`, readable by every
  user on the machine. Run `sudo chmod 600 ~/.via/vpn_service_config.xml` (`exeter-vpn doctor` checks for this).
- `exeter-vpn` prompts for your password and never stores it. You can point `EXETER_VPN_PASSFILE` at a
  mode-600 file if you really want to.
- `via-cli` takes the keystore password as a command-line argument, so other local users can briefly see
  it in `ps`. Another reason not to reuse your University password for it.

## Ubuntu / Debian

Exeter also publishes a `.deb` (`via_4.7.6.2601123-deb_amd64.deb`). Everything after the install step is
identical, and `exeter-vpn` works once `via-cli` is on your PATH (`exeter-vpn install` itself is dnf-only).
Exeter notes a DNS issue on Ubuntu 20.04, which `exeter-vpn dns` fixes.

## For AI coding agents

This repo includes instructions for coding agents: [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md), and
Claude Code skills in [.claude/skills/](.claude/skills/). Open the repo in Claude Code and ask
*"set up the Exeter VPN"* or *"my Exeter VPN is broken"*.

## Licence

MIT. See [LICENSE](LICENSE). The VIA client itself is proprietary (HPE Aruba) and is downloaded from the
University's website, not redistributed here.
