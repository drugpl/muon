#compdef muon
_muon() { 
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments \
    '1: :->action1'\
    '*: :->action2'

  case $state in
    action1)
      _arguments '1:Actions:(help start stop checkout)'
      ;;
    action2)
      case $words[2] in
        checkout)
          if [ -d .git/refs/heads ]
          then
            compadd "$@" $(ls .git/refs/heads)
          fi
          ;;
        help)
          compadd "$@" start stop checkout
          ;;
        *)
          _files 
      esac
      ;;
    *)
      _files
  esac
}

_muon "$@"
