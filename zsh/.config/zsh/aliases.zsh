# ── Files ─────────────────────────────────────
alias ls="eza --icons --group-directories-first"
alias l="eza --icons --group-directories-first -la"
alias ll="eza --icons --group-directories-first -la"
alias lt="eza --icons --tree --level=2"
alias la="eza --icons --group-directories-first -a"
alias cat="bat --paging=never"

# ── Git ───────────────────────────────────────

function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo master
}
alias g="git"
alias ga="git add"
alias gaa="git add --all"
alias gb="git branch"
alias gba="git branch -a"
alias gc="git commit -v"
alias gc!="git commit -v --amend"
alias gcm='git checkout $(git_main_branch)'  # 切到 main/master（omz 原意）
alias gco="git checkout"
alias gcb="git checkout -b"
alias gd="git diff"
alias gds="git diff --staged"
alias gf="git fetch"
alias gl="git pull"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias glg="git log --stat"
alias glog="git log --oneline --decorate --graph"
alias gloga="git log --oneline --decorate --graph --all"
alias gm="git merge"
alias gmom='git merge origin/$(git_main_branch)'
alias grb="git rebase"
alias grbi="git rebase -i"
alias gst="git status"
alias gss="git status -s"
alias gsb="git status -sb"
alias gsta="git stash push"
alias gstp="git stash pop"
alias gstl="git stash list"
alias gsw="git switch"
alias gswc="git switch -c"
alias grh="git reset HEAD"
alias grhh="git reset HEAD --hard"
alias gcp="git cherry-pick"
# —— 从 oh-my-zsh git 插件补回的高频别名 ——
alias gcl="git clone"
alias gcmsg="git commit -m"
alias gpsup='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'  # 推新分支
alias grbc="git rebase --continue"
alias grba="git rebase --abort"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gpristine='git reset --hard && git clean -dffx'  # 彻底还原工作区（慎用）
# 删除所有已合并进主分支的本地分支
alias gbda='git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch))\s*$)" | command xargs git branch -d 2>/dev/null'

# ── Neovim ────────────────────────────────────
alias vi="nvim"
alias lazyvim="NVIM_APPNAME=lazyvim nvim"
alias nvchad="NVIM_APPNAME=nvchad nvim"
alias astronvim="NVIM_APPNAME=astronvim nvim"
alias nvimdots="NVIM_APPNAME=nvimdots nvim"

# ── Caffeinate ────────────────────────────────
alias awake="caffeinate -disu"
alias awake1="caffeinate -disu -t 3600"
alias awake2="caffeinate -disu -t 7200"

# ── tmux ──────────────────────────────────────
# 全新 session 默认从 ~/Code 启动（attach / resurrect 恢复不受影响）
tmux() { ( cd ~/Code 2>/dev/null; command tmux "$@" ) }
