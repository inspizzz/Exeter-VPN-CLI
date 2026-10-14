# bash completion for exeter-vpn
_exeter_vpn() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmds="install login config connect disconnect up down status gui doctor logs mtu dns clean help version"
  if (( COMP_CWORD == 1 )); then COMPREPLY=($(compgen -W "$cmds" -- "$cur")); return; fi
  case ${COMP_WORDS[1]} in
    login)  COMPREPLY=($(compgen -W "--pin --passfile" -- "$cur")); [[ $prev == --passfile ]] && COMPREPLY=($(compgen -f -- "$cur")) ;;
    logs)   COMPREPLY=($(compgen -W "-f --follow -n" -- "$cur")) ;;
    mtu)    if [[ $prev == reset ]]; then COMPREPLY=($(compgen -W "--all" -- "$cur"))
            else COMPREPLY=($(compgen -W "probe reset 1240 1200" -- "$cur")); fi ;;
    config) COMPREPLY=($(compgen -W "user" -- "$cur")) ;;
  esac
}
complete -F _exeter_vpn exeter-vpn
