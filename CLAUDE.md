# CLAUDE.md

@AGENTS.md

## Claude Code specifics

- Skills in `.claude/skills/`:
  - `exeter-vpn-setup`: first-time install → login → connect, step by step with the user.
  - `exeter-vpn-troubleshoot`: diagnose a VPN that won't sign in, won't connect, or connects but doesn't work.
- Interactive steps (password prompts, phone approval) must be run by the user. Suggest
  `! exeter-vpn login` / `! exeter-vpn connect` so the output lands in the conversation.
- `.claude/settings.json` pre-allows the read-only commands (`exeter-vpn status|doctor|logs`, `ip`,
  `resolvectl status`). Anything that changes the network still prompts, which is intended.
- When connected, the VPN is a full tunnel through a lossy gateway path, so your own web and API requests may
  be slow or time out (`gh`, `git push` included). Retry before assuming something else is broken.
- Browsing <https://mysignins.microsoft.com> (e.g. with Claude in Chrome) is useful to check MFA methods,
  but the user must sign in and make any account changes themselves.
