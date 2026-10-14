# Installing the VIA client by hand

`exeter-vpn install` does all of this for you. These are the equivalent manual steps, in case you want to
see what it runs or do it yourself. The University publishes the Linux client at
<https://www.exeter.ac.uk/departments/it/help/howdoi/vpn/>.

```bash
base=https://www.exeter.ac.uk/v8media/universityofexeter/it/documents/networks/vpn
curl -LO $base/rootca.pem
```

## Fedora / RHEL

The "RHEL/CentOS" download is a **self-extracting installer** rather than a plain RPM, but it has an
`extract` mode that produces one:

```bash
curl -LO $base/via-4.7.6.2601123-rpm.x86_64_bin
chmod +x via-4.7.6.2601123-rpm.x86_64_bin
./via-4.7.6.2601123-rpm.x86_64_bin extract via.rpm   # needs only dbus + libtdb
sudo dnf install ./via.rpm
sudo systemctl enable --now via-vpn
```

## Ubuntu / Debian

```bash
curl -LO $base/via_4.7.6.2601123-deb_amd64.deb
sudo apt install lsb-release ./via_4.7.6.2601123-deb_amd64.deb
sudo systemctl enable --now via-vpn
```

How the `.deb` differs from the RPM:

- Its post-install script **restarts NetworkManager**, so your connection drops for a few seconds.
- The same script calls `lsb_release` and fails without it (minimal Debian), leaving the package
  half-configured. That's why `lsb-release` is installed alongside it.
- `via-vpn` is a SysV init script instead of a systemd unit. `systemctl` handles it the same way.
- `exeter-vpn dns` needs systemd-resolved, which Ubuntu has by default and plain Debian often doesn't.
  Without it, `exeter-vpn dns` prints the campus DNS servers to add to `/etc/resolv.conf` instead of
  changing anything. Exeter notes a DNS issue on Ubuntu 20.04, which `exeter-vpn dns` fixes.
- For the keyring feature, `secret-tool` comes from `libsecret-tools`.

## Import Exeter's root CA (both)

```bash
via-cli session start
via-cli -k '<choose-a-keystore-password>' cert import --CA --user rootca.pem
```

**The keystore password is one you invent.** The first time you pass `-k`, VIA uses that value as its local
keystore password, and every later `via-cli` command needs it. Don't reuse your University password.

## GUI autostart

Both packages install `/etc/xdg/autostart/via-auto.desktop`, which starts the VIA GUI at every login.
Starting the GUI drops a tunnel made by the CLI, so `exeter-vpn install` offers to disable it for your user
by writing a `Hidden=true` copy to `~/.config/autostart/via-auto.desktop`.
