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

# ccwork <slug> [dir]  在 ccbot session 起一个「可被手机接管」的会话（含 worktree）
# dir 默认 ~/Code/<slug 冒号前的部分>。窗口跑 worktree 包装脚本：git 仓库自动
# 建 worktree+分支后进 claude。之后手机建 topic 发消息 → 窗口选择器点它即接管。
ccwork() {
  local slug="$1" dir="${2:-$HOME/Code/${1%%:*}}"
  [[ -z "$slug" ]] && { echo "用法: ccwork <slug> [dir]"; return 1; }
  [[ -d "$dir" ]] || { echo "❌ 目录不存在: $dir"; return 1; }
  command tmux has-session -t ccbot 2>/dev/null || { echo "❌ 没有 'ccbot' tmux session（CCBot 守护进程没起？）"; return 1; }
  command tmux new-window -t ccbot -n "$slug" -c "$dir" "$HOME/.ccbot/claude-worktree.sh"
  ccto "$slug"   # 顺手切过去
}

# ── GLM（智谱）委派 ────────────────────────────
# glm "任务描述"  用 GLM-4.6 跑一轮 headless claude，让 GLM 帮你干活。
# GLM 端点是 Anthropic 兼容的，所以套一层 claude -p 即可获得完整 agent 能力。
# 密钥读自 ~/.config/glm/apikey（仓库外真实文件，永不入库）。
# 额外 flag 透传：glm --model glm-4.5 "..."、glm --permission-mode acceptEdits "改代码"。
glm() {
  local keyfile=~/.config/glm/apikey
  [[ -r "$keyfile" ]] || { echo "❌ 没找到 GLM 密钥：$keyfile" >&2; return 1; }
  ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$(< "$keyfile")" \
  ANTHROPIC_MODEL="glm-4.6" \
  ANTHROPIC_SMALL_FAST_MODEL="glm-4.5-air" \
  command claude -p "$@"
}
