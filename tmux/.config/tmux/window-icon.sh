#!/bin/bash
case "$1" in
  zsh|bash|fish|sh)    icon="" ;;
  nvim|vim|vi)         icon="" ;;
  node)                icon="" ;;
  python|python3|ipython) icon="" ;;
  git|tig|lazygit)     icon="" ;;
  docker|docker-compose) icon="" ;;
  ssh|mosh)            icon="󰣀" ;;
  htop|top|btop)       icon="" ;;
  make|cmake|cargo)    icon="" ;;
  npm|pnpm|yarn|bun)   icon="" ;;
  go)                  icon="" ;;
  ruby|irb)            icon="" ;;
  rust|rustc)          icon="" ;;
  lua)                 icon="" ;;
  java|javac)          icon="" ;;
  curl|wget)           icon="󰖟" ;;
  cat|less|bat)        icon="" ;;
  man)                 icon="󰋖" ;;
  tmux)                icon="" ;;
  claude)              icon="✦" ;;
  *)                   icon="" ;;
esac
echo "$icon $1"
