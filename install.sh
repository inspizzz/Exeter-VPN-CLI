#!/usr/bin/env bash
# Installs the exeter-vpn CLI (and bash completion) for the current user.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
bindir="${PREFIX:-$HOME/.local}/bin"
compdir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
install -Dm755 "$here/bin/exeter-vpn" "$bindir/exeter-vpn"
install -Dm644 "$here/completions/exeter-vpn.bash" "$compdir/exeter-vpn"
echo "Installed $bindir/exeter-vpn"
case ":$PATH:" in *":$bindir:"*) ;; *) echo "Add $bindir to your PATH (e.g. in ~/.bashrc)." ;; esac
echo "Next: exeter-vpn install   (then: exeter-vpn login, exeter-vpn connect)"
