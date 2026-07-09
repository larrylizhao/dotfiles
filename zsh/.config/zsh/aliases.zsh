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

# ── CCBot ─────────────────────────────────────
# ccto [topic]  跳到 ccbot session 里名字匹配 <topic> 的窗口
# （窗口名 = Telegram topic 标题）。大小写不敏感、子串匹配。
# 无参数 → fzf 选择器。已在 tmux 内用 switch-client，在外则 attach。
ccto() {
  local session=ccbot line idx
  command tmux has-session -t "$session" 2>/dev/null || { echo "❌ 没有 '$session' tmux session"; return 1; }
  if [[ -n "$1" ]]; then
    line=$(command tmux list-windows -t "$session" -F '#{window_index} #{window_name}' | grep -iF -- "$1" | head -1)
    if [[ -z "$line" ]]; then
      echo "❌ 没有匹配 '$1' 的窗口。$session 现有窗口："
      command tmux list-windows -t "$session" -F '  #{window_index}: #{window_name}'
      return 1
    fi
  else
    line=$(command tmux list-windows -t "$session" -F '#{window_index} #{window_name}' | fzf --height 40% --reverse) || return 0
    [[ -z "$line" ]] && return 0
  fi
  idx=${line%% *}   # 用窗口序号定位，兼容含空格/中文的 topic 名
  if [[ -n "$TMUX" ]]; then
    command tmux switch-client -t "$session" \; select-window -t "$session:$idx"
  else
    command tmux attach -t "$session" \; select-window -t "$session:$idx"
  fi
}
