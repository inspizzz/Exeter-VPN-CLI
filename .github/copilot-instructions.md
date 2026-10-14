# Copilot instructions

Follow [AGENTS.md](../AGENTS.md) at the repo root. In short:

- `bin/exeter-vpn` is a single-file, dependency-free bash CLI (`set -euo pipefail`, `cmd_<name>` functions,
  UI helpers `step ok warn bad hint die ask spin`). New subcommands also go in `cmd_help`, `main`, the bash
  completion, and the README.
- Never put passwords in argv or logs; pass them to curl via a mode-600 temp file.
- Gateway requests go through `http()`, which retries only on connect hangs (a resend triggers a second MFA push).
- The "VIA Next/New Pin" page means wrong credentials, not an MFA code request.
- Never commit credentials, `profile.xml`, cookies, HAR files, or anything under `private/`.
- Test with `bash -n bin/exeter-vpn` and the read-only `exeter-vpn help|doctor|status`.
