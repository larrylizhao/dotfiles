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
# glm "任务描述"  跑一轮 headless claude 让 GLM 帮你干活（Anthropic 兼容端点）。
# 自动选模型：按偏好顺序（好→兜底）用 1-token 预检额度，永远用「当前可用的最好模型」，
# 额度用光自动降级；预检避免了把已耗尽的模型丢给 claude 傻等重试。
# 密钥读自 ~/.config/glm/apikey（仓库外真实文件，永不入库）。
# 覆盖：GLM_MODELS="glm-5.2 glm-4.5-air" 改偏好顺序；glm --model X "..." 跳过自动选择。
# 端点行为对齐官方 Claude Code 配置：长超时 + 关闭对 Anthropic 的非必要遥测回连。
glm() {
  local keyfile=~/.config/glm/apikey
  local base="https://open.bigmodel.cn/api/anthropic"
  [[ -r "$keyfile" ]] || { echo "❌ 没找到 GLM 密钥：$keyfile" >&2; return 1; }
  local key; key="$(< "$keyfile")"

  # 端点行为对齐官方配置：长超时（复杂任务不被切）+ 关闭对 Anthropic 的非必要回连
  local -a envcommon=(
    ANTHROPIC_BASE_URL="$base"
    ANTHROPIC_AUTH_TOKEN="$key"
    API_TIMEOUT_MS="3000000"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
    ANTHROPIC_SMALL_FAST_MODEL="glm-4.5-air"
  )

  # 你显式 --model 时尊重之，跳过自动选择
  # 用 env 而非赋值前缀：数组展开的 VAR=val 不会被 zsh 当赋值前缀识别，必须交给 env
  if [[ "$*" == *"--model"* ]]; then
    env "${envcommon[@]}" claude -p "$@"
    return
  fi

  # 偏好顺序：最好 → 兜底（glm-5.2 旗舰 → glm-4.6 → air 额度最厚兜底）
  local -a models=(${=GLM_MODELS:-glm-5.2 glm-4.6 glm-4.5-air})
  local m resp http body model=""
  for m in "${models[@]}"; do
    resp=$(curl -s --max-time 15 -w $'\n%{http_code}' "$base/v1/messages" \
      -H "x-api-key: $key" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
      -d "{\"model\":\"$m\",\"max_tokens\":1,\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}")
    http="${resp##*$'\n'}"; body="${resp%$'\n'*}"
    if [[ "$http" == "200" && "$body" != *'"type":"error"'* ]]; then
      model="$m"; break
    fi
    echo "⚠️ $m 不可用（HTTP $http），降级尝试下一个…" >&2
  done
  [[ -z "$model" ]] && { echo "❌ 所有候选模型都不可用（额度耗尽或端点故障）" >&2; return 1; }
  [[ "$model" != "${models[1]}" ]] && echo "→ 已降级到 $model" >&2

  env "${envcommon[@]}" ANTHROPIC_MODEL="$model" claude -p "$@"
}
