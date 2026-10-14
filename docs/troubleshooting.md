# Troubleshooting

Start with `exeter-vpn doctor`. It checks the most common problems.

## Signing in

**"VIA Next/New Pin" page, a 6-digit code box, or "Login failed" after entering a code**
: Wrong username or password, in almost every case. The gateway shows this page for *any* wrong
  password, so it is *not* an MFA code request. Check the password at <https://mysignins.microsoft.com>. If
  you saved it in a file, check that too: a typo there cost us a whole day. Changing MFA methods won't help.

**No notification on the phone**
: Open Microsoft Authenticator *before* signing in. At <https://mysignins.microsoft.com/security-info>,
  make sure you have Authenticator (push) or a phone number, and that "Microsoft Authenticator – notification"
  or "Phone – call" is your default. Codes ("Authenticator app or hardware token – code") are not supported
  on the VPN, according to Exeter IT.

**Error -8949 / "Failed to establish secure session"**
: The MFA request timed out. You have about 30 seconds. Cancel, wait a few minutes, and try again.

**Repeated failures**
: Stop after a few attempts. Many failed or denied MFA requests in a short time can temporarily block MFA
  on your account.

## Connecting

**"Failed to connect - another client (GUI or CLI) is probably running"**
: The VIA GUI is open. Close it (`pkill via-ui`) or use the GUI instead of the CLI.

**Connects, then drops a few seconds later**
: Was the GUI just started, perhaps by the login autostart? It force-disconnects existing tunnels when it
  starts. Check `exeter-vpn logs` for `force disconnecting any existing on applications start`.

**Connected, but some things hang (uploads, `git push`, some apps or CLIs, SSH), while the browser works**
: MTU. VIA drops outgoing packets above a cap a few bytes under the MTU it connected with (1250 gives 1246),
  so full-size packets vanish. Downloads still work, which makes it confusing. `exeter-vpn mtu probe` shows
  the cap, and `exeter-vpn mtu <N>` sets the interface to it. `connect` does this automatically. Raising the MTU
  above the cap (e.g. `mtu 1250` on a session that connected at 1220) breaks things. A quick test is
  `curl -4 --curves X25519 https://api.github.com` (small TLS hello) versus plain `curl -4 https://api.github.com`:
  if only the first works, it's this. Browsers often look fine because sites with IPv6 bypass the tunnel.

**Names under `ex.ac.uk` don't resolve, or `status` says "DNS none set"**
: VIA receives the campus DNS servers (`dns :"144.173.119.22,144.173.119.23"` in the service log) but
  doesn't always register them with systemd-resolved, so lookups keep going to your home router. Public
  names still work, but campus-only ones don't. `exeter-vpn dns` sets those servers on `via_vpn` and then
  runs `resolvectl domain via_vpn ex.ac.uk '~.'`, Exeter's documented workaround, to send all lookups to
  them. It lasts until the next reconnect.

**`connect` says "User name required" / `VIA_ERROR_NORESOURCE`**
: VIA has no saved sign-in, which is normal on a fresh install. Current `exeter-vpn connect` handles this by
  asking for your University password once. Older versions just failed.

**Gateway sometimes doesn't answer / downloads hang**
: The route to 144.173.255.40 is lossy (we saw roughly 1 in 6 TCP connects hang). Retry. `exeter-vpn`
  retries connects automatically.

**Nothing works at all**
: On campus or eduroam? The VPN only works from outside. Use a phone hotspot to test.

## The GUI

**Text boxes are blank or invisible**
: VIA's GUI is Qt5. On a Plasma 6 desktop without the Qt5 Breeze style, its colours clash.
  Use `exeter-vpn gui`, or `QT_QPA_PLATFORMTHEME=generic QT_STYLE_OVERRIDE=Fusion via-ui`, or install
  `plasma-breeze-qt5`.

**Spinner never stops while "downloading" the profile**
: The download already failed. The GUI crashes its own progress timer. Look in `~/.via/app-via.log`
  for `Profile is in unexpected format`, which usually means wrong credentials (see the top of this page).

**Certificate warning in the GUI**
: The GUI keystore may not include the CA you imported through the CLI. The real chain is valid
  (Sectigo → AAA Certificate Services).

## Collecting information for Exeter IT

```bash
exeter-vpn doctor
exeter-vpn logs -n 80
grep -a 'Oct 14 13:3' /usr/share/via/logs/app-vpn.log | grep -avE 'crypted frame' | tail -200   # adjust the time
```

Include the times of your attempts. Never send `~/.via/vpn_service_config.xml`, because it contains your password.
