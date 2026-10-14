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

**Connected, but some things hang (web pages, SSH, large transfers)**
: MTU. `exeter-vpn mtu probe` finds the largest packet that gets through, then set it with
  `exeter-vpn mtu <N>`. A colleague fixed an "endless loop / connected but no data" VPN this way.
  The setting lasts until the next reconnect.

**Names under `ex.ac.uk` don't resolve**
: `exeter-vpn dns` runs `resolvectl domain via_vpn ex.ac.uk '~.'`, which is Exeter's documented workaround
  and sends all lookups to the campus resolvers.

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
