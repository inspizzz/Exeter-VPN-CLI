---
name: exeter-vpn-setup
description: Set up the University of Exeter VPN (Aruba VIA, remote.exeter.ac.uk) on Fedora or Ubuntu/Debian from scratch - install the client, import the CA, sign in with MFA, download the profile and connect. Use when the user asks to install, set up or get started with the Exeter VPN.
---

# Exeter VPN first-time setup

Walk the user through this in order. Run the read-only checks yourself. The user runs anything that
prompts for a password, needs sudo or needs their phone, **in their own terminal**, and pastes the output
back. The `!` prefix has no TTY, so sudo prompts fail there.

## 0. Preconditions (check, don't assume)
- Fedora/RHEL with `dnf`, or Ubuntu/Debian with `apt-get`: `command -v dnf apt-get`. Ubuntu/Debian is only
  tested up to the install step, so say so, and see the README's Ubuntu / Debian section for the differences.
- **Off campus, not on eduroam**: `nmcli -t -f active,ssid dev wifi | grep '^yes'`.
- The user has Microsoft Authenticator (push) or a phone number as the default MFA method
  (<https://mysignins.microsoft.com/security-info>, which they check and change themselves).

## 1. Install the CLI
`./install.sh` (safe: copies into `~/.local/bin`). Confirm `exeter-vpn --version`.

## 2. Install the VIA client (needs sudo, so ask first)
User runs `exeter-vpn install` in their terminal. It downloads the official installer from exeter.ac.uk, extracts the RPM and
`dnf install`s it (Fedora), or `apt-get install`s the `.deb` (Ubuntu/Debian, which restarts NetworkManager, so
warn them first), enables `via-vpn.service`, offers to disable the GUI autostart, and imports `rootca.pem`.
Tell them **before** they run it: the keystore password they type now is *new and of their choosing*
(not the University password), and they must remember it.

## 3. Sign in and fetch the profile
User runs `exeter-vpn login` in their terminal. They enter the University password and approve the Authenticator
notification within ~30 s. Success prints the profile name (e.g. `UoE-VIA-Connection`).
- If it reports the **"VIA Next/New Pin"** page, the username or password is wrong. Do **not** start changing
  MFA settings. Have them verify the password by signing in at mysignins.microsoft.com, then retry.
  Stop after 2–3 failures (MFA lockout risk).

## 4. Connect and verify
User runs `exeter-vpn connect` in their terminal. The first time, it also asks for the University password,
because VIA has no saved sign-in yet. It then measures the tunnel MTU for this network and may ask for sudo
once to lower it. Then you run `exeter-vpn status` and `exeter-vpn doctor` and explain the result. If `status`
shows "DNS none set" or campus names don't resolve, offer `exeter-vpn dns`. If big transfers hang, run
`exeter-vpn mtu probe`.

## 5. Finish
- Remind them of the one-client rule (GUI **or** CLI; the GUI kills CLI tunnels when it starts).
- If `doctor` flags `~/.via/vpn_service_config.xml` permissions, suggest `sudo chmod 600` on it.
