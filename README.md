# Exeter VPN CLI

Connect to the **University of Exeter VPN** (`remote.exeter.ac.uk`, Aruba VIA) from **Fedora Linux**
(and Ubuntu / Debian), with a small command-line tool, `exeter-vpn`, that wraps the steps that are fiddly on Linux.

> Unofficial and not affiliated with the University. For account or MFA problems, contact
> Exeter IT (sid@exeter.ac.uk). Tested on Fedora 43 (KDE Plasma 6) with VIA 4.7.6, October 2026.
> Ubuntu / Debian: the install step was tested in Ubuntu 24.04 and Debian 13 containers; the tunnel itself
> hasn't been tested there yet (see [Ubuntu / Debian](#ubuntu--debian)).

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
git clone https://github.com/inspizzz/Exeter-VPN-CLI.git
cd Exeter-VPN-CLI
./install.sh            # puts `exeter-vpn` in ~/.local/bin (+ bash completion)

exeter-vpn install      # downloads the official VIA client from exeter.ac.uk, installs it, imports the CA
exeter-vpn login        # password + approve on your phone -> downloads and loads your VPN profile
exeter-vpn connect      # brings the tunnel up (asks for your University password the first time)
exeter-vpn status
```

After the first time, you only need `exeter-vpn connect` and `exeter-vpn disconnect`. Run `login` again if
the profile stops working, for example after a password change.

`connect` also checks the largest packet the tunnel carries on your current network and fixes the MTU if
VIA's default is too big (see [MTU](#mtu) below). That may ask for sudo once per network.

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
| Connected, but web pages or SSH hang while small things like ping work | MTU, see [below](#mtu). `exeter-vpn mtu probe` checks it, `exeter-vpn mtu <N>` sets and remembers a value |
| `*.ex.ac.uk` names don't resolve | `exeter-vpn dns`: sets the campus DNS servers on `via_vpn` (VIA sometimes doesn't) and applies Exeter's documented workaround, `resolvectl domain via_vpn ex.ac.uk '~.'` |
| Requests to the gateway hang now and then | The path to `remote.exeter.ac.uk` is lossy, so retry. The tool retries automatically |
| Gateway won't respond at all | Are you on eduroam or a campus network? Use a hotspot or home Wi-Fi |

### MTU

The MTU is the largest packet your machine sends into the tunnel. If it's even slightly too big, those
packets vanish without any error. Downloads and small requests still work, but **uploads, `git push`, large
API requests and some TLS connections hang**. That's the "connected but no data was exchanged" problem a
colleague fixed by lowering the MTU.

What we measured (Aruba VIA 4.7.6, `remote.exeter.ac.uk`):

- **VIA drops outgoing packets a few bytes below the MTU it connected with.** With the gateway's
  `<via_mtu>1250</via_mtu>`, the largest packet that gets out is **1246 bytes**. Connecting at 1240 gives 1230,
  and 1220 gives 1214. It looks like 16-byte cipher-block rounding. Incoming packets aren't affected.
- **Raising the interface MTU after connecting doesn't raise this cap**, and starting VIA lower lowers the cap
  too. So "just lower it until it works" can slide downwards, and someone else's number (e.g. 1400) tells
  you nothing.
- **Big TLS hellos are the first casualty.** Modern clients send post-quantum key shares, making the very
  first packet full-size, so some apps (e.g. CLI tools talking to APIs over IPv4) can't even connect while
  a browser seems fine.

`exeter-vpn connect` handles this:

1. After connecting, it pings campus DNS with different packet sizes to find the largest that gets out (a
   few seconds).
2. If the MTU is above that, it lowers the interface MTU to exactly that size (sudo) and remembers the value
   for this network (keyed by your router, in `~/.config/exeter-vpn/mtu`).
3. Next time on that network, it writes the value into the profile (`<via_mtu>`) before connecting, so VIA
   starts at a size it actually carries, with no sudo. If that doesn't hold, it stops lowering the start
   value and just fixes the MTU with sudo after each connect.

`exeter-vpn mtu` shows the current and remembered values, `mtu probe` re-measures, `mtu <N>` sets and remembers
a value (it warns if `N` doesn't get through), and `mtu reset [--all]` forgets it.

**IPv6 bypasses the tunnel.** VIA only tunnels IPv4, so on a home network with IPv6, sites that have IPv6 go
straight out, not through the VPN. That's why "the browser still works" isn't proof that the tunnel works.
Test with `curl -4`.

More detail: [docs/troubleshooting.md](docs/troubleshooting.md) and [docs/how-it-works.md](docs/how-it-works.md).

## Security notes

- VIA stores your University password **in plain text** in `~/.via/vpn_service_config.xml`, readable by every
  user on the machine. Run `sudo chmod 600 ~/.via/vpn_service_config.xml` (`exeter-vpn doctor` checks for this).
- `exeter-vpn` prompts for your password and never stores it. You can point `EXETER_VPN_PASSFILE` at a
  mode-600 file if you really want to.
- The VIA keystore password: the first time you type it, `exeter-vpn` offers to keep it in your desktop
  keyring (GNOME Keyring / KDE Wallet, via `secret-tool`), so `connect` and `disconnect` stop asking.
  `exeter-vpn forget-keystore` removes it. It's handed to `via-cli` through a mode-600 temp file
  (`--keypassfile`), not on the command line where `ps` would show it. Still, don't reuse your University
  password for it.

## Ubuntu / Debian

`exeter-vpn install` detects `apt-get` and installs Exeter's `.deb` (`via_4.7.6.2601123-deb_amd64.deb`)
instead of the RPM. Everything else works the same way. Things that differ from Fedora:

- **Status:** installing was tested in Ubuntu 24.04 and Debian 13 containers. Login, connect, MTU and DNS
  haven't been tested on a real Ubuntu/Debian machine yet. Reports are welcome.
- Installing **restarts NetworkManager** (the package's own post-install script does this), so your
  connection drops for a few seconds.
- The package's post-install script needs `lsb_release`. `exeter-vpn install` installs `lsb-release` first
  if it's missing (minimal Debian), otherwise the package is left half-configured.
- `via-vpn` is a SysV init script on Debian/Ubuntu rather than a systemd unit. `systemctl` handles it the same way.
- **DNS:** `exeter-vpn dns` needs systemd-resolved, which Ubuntu has by default and plain Debian often doesn't.
  Without it, DNS comes from `/etc/resolv.conf`, which `exeter-vpn` won't edit (NetworkManager or resolvconf
  own it). `exeter-vpn dns` then prints the campus servers to add, or you can `sudo apt install systemd-resolved`.
  Exeter notes a DNS issue on Ubuntu 20.04, which `exeter-vpn dns` fixes.
- To keep the keystore password in your keyring, `secret-tool` comes from `libsecret-tools`
  (`sudo apt install libsecret-tools`).

Manual equivalent of the install step:

```bash
base=https://www.exeter.ac.uk/v8media/universityofexeter/it/documents/networks/vpn
curl -LO $base/via_4.7.6.2601123-deb_amd64.deb
curl -LO $base/rootca.pem
sudo apt install lsb-release ./via_4.7.6.2601123-deb_amd64.deb
sudo systemctl enable --now via-vpn
```

Then import the CA as in the Fedora section above.

## For AI coding agents

This repo includes instructions for coding agents: [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md), and
Claude Code skills in [.claude/skills/](.claude/skills/). Open the repo in Claude Code and ask
*"set up the Exeter VPN"* or *"my Exeter VPN is broken"*.

## Licence

MIT. See [LICENSE](LICENSE). The VIA client itself is proprietary (HPE Aruba) and is downloaded from the
University's website, not redistributed here.
