---
name: exeter-vpn-troubleshoot
description: Diagnose and fix a broken University of Exeter VPN (Aruba VIA) on Linux - sign-in failures, "VIA Next/New Pin" / code prompts, missing MFA notifications, tunnels that drop, connected-but-nothing-works, DNS or MTU problems, invisible GUI text. Use when the Exeter VPN is not working.
---

# Exeter VPN troubleshooting

Gather evidence before theorising. Read-only commands are safe to run yourself:

```bash
exeter-vpn doctor
exeter-vpn status
exeter-vpn logs -n 80          # service log, noise filtered
tail -n 200 ~/.via/app-via.log  # GUI/CLI side: web login + profile download
```

## Decision guide

1. **Sign-in shows "VIA Next/New Pin", asks for a 6-digit code, or says "Login failed"**
   → **wrong username or password** (the gateway shows this page for any wrong password). Verify the
   credentials first: does the user's password work at mysignins.microsoft.com? Is a saved password file
   stale? Only after the credentials are confirmed should you look at MFA methods. Stop after 2–3 attempts.
2. **GUI spinner never stops / `Profile is in unexpected format` / HTTP 401 on `/via/config`** → same as 1.
3. **`Failed to connect - another client (GUI or CLI) is probably running`** → `via-ui` is open
   (`pgrep -a via-ui`). Ask before closing it.
4. **Connected, then dropped seconds later** → `grep -a 'force disconnecting' /usr/share/via/logs/app-vpn.log`.
   If present, the GUI started (often via autostart) and killed the tunnel. One client only.
5. **Connected but pages/SSH hang** → `exeter-vpn mtu probe`, then `exeter-vpn mtu <N>` (ask first). Also
   check DNS: `getent hosts www.exeter.ac.uk`, and if that fails, `exeter-vpn dns` (ask first).
6. **Gateway unreachable or requests hang** → lossy path, so retry. Persistent? Check they're not on eduroam
   or campus (`exeter-vpn doctor`).
7. **No push notification** (credentials confirmed correct) → the user opens Authenticator first and checks
   the default method at mysignins.microsoft.com/security-info (push or call; codes aren't supported).
8. **Invisible GUI text** → `exeter-vpn gui` (Qt5-on-Plasma-6 workaround).

## Reading the service log
`/usr/share/via/logs/app-vpn.log` contains binary bytes, so always `grep -a`. Key markers:
`Received EAP SUCCESS!`, `Global status file /vpn/status,…`, `force disconnecting any existing on
applications start`, `Computed Path MTU`. Ignore `Cann't possible to send crypted frame -8807` spam.

## Rules
- Never ask for, type, or print the University password or keystore password; the user types them.
- Ask before connect/disconnect/login/install, `sudo`, or killing `via-ui`.
- If you're connected through the VPN yourself, your own requests can be slow. Retry before concluding.
- If everything client-side checks out and sign-in still fails with confirmed-correct credentials,
  draft (don't send) an email to Exeter IT (sid@exeter.ac.uk) with attempt times and `exeter-vpn doctor` output.
