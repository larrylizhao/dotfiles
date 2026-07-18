#!/usr/bin/env zsh
# ── CCBot 远程控制工具集 ───────────────────────────────────────────────
# 从 aliases.zsh 抽出，聚合所有 CCBot（Telegram ↔ tmux 桥）相关命令。
# 由 .zshrc source。依赖：tmux、fzf、python3、~/.ccbot/claude-worktree.sh。
#
#   ccto   [topic]              跳到 ccbot session 里某个窗口（模糊匹配 / fzf）
#   ccwork <slug> [dir]         在 ccbot 起一个可被手机接管的会话（含 worktree）
#   cctake <session>:<window>   把别的 session 的窗口「迁进」ccbot（move，一次性转交）
#   cclink <session>:<window>   把别的 session 的窗口「链接」进 ccbot（link，原 session 保留）
#   ccspawn <name> [token]      起一套独立 CCBot 实例：一个群 = 一个 tmux session
#
# ── 已知局限 / TODO ────────────────────────────────────────────────────
# ccto/ccwork/cctake/cclink 目前写死 primary 实例（session=ccbot, ~/.ccbot）。
# ccspawn 起的独立实例（如 product：session=product, dir=~/.ccbot-product，
# session_map key 前缀 product:）用不了这几个命令——只能手动 tmux 操作，或直接
# 在该 session 里干活（cctake/cclink 本就是「往 primary 拉窗口」的语义，对独立实例
# 意义不大；主要缺的是 per-实例的 ccto/ccwork）。
#
# 将来若常用多实例，重构方向已定：做 `cci <instance> <子命令>` 分发器——
#   · 把「实例 → (session名, CCBOT_DIR, key前缀)」解析收敛到单一入口；
#   · ccto/ccwork/… 保留为「默认 instance=ccbot」的简写，委派到共享核心；
#   · cci product work slug / cci product to foo 作为多实例前端。
# 优于「给每个函数加 -i」：后者要在 N 个函数里重复 flag 解析，且省不掉核心参数化。
# 现状：单实例够用，暂不重构（YAGNI）。
# ───────────────────────────────────────────────────────────────────────

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

# _ccbot_rekey <window-id>  把 session_map 里 <任意前缀>:<wid> 的 key 改成 ccbot:<wid>，
# 让 CCBot 的监控（只认 ccbot: 前缀）能读到该窗口输出。原子写，避免和 bot 轮询撞车。
_ccbot_rekey() {
  python3 - "$HOME/.ccbot/session_map.json" "$1" <<'PY'
import json, sys, os, tempfile
f, wid = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(f))
except (OSError, ValueError):
    d = {}
for k in list(d):
    if k.endswith(":" + wid) and not k.startswith("ccbot:"):
        d["ccbot:" + wid] = d.pop(k); print("rekey ->", "ccbot:" + wid)
fd, t = tempfile.mkstemp(dir=os.path.dirname(f))
with os.fdopen(fd, "w") as fh:
    json.dump(d, fh, ensure_ascii=False, indent=2)
os.replace(t, f)
PY
}

# _ccbot_pin_name <window-id> <name>  固定窗口名：关掉 automatic-rename / allow-rename
# （否则 claude 会把窗口名刷成自己的版本号，如 2.1.209），并设为 <name>。
# 之后在 Telegram 改 topic 名仍能覆盖（显式 rename-window 不受这两个开关限制）。
_ccbot_pin_name() {
  command tmux set-option -w -t "$1" automatic-rename off 2>/dev/null
  command tmux set-option -w -t "$1" allow-rename off 2>/dev/null
  command tmux rename-window -t "$1" "$2"
}

# cctake <session>:<window>  把别的 tmux session 里在跑 claude 的窗口「迁进」ccbot（move），
# 并修正 session_map，使其可被 Telegram 接管。适合「一次性转交给手机」。
# 原理：CCBot 只监控 key 以 "ccbot:" 开头的条目；迁移保留 window-id，改前缀即打通输出。
# 注意：move 会把窗口移出原 session（原 session 若只剩这一个窗口会消失）。
cctake() {
  local src="$1"
  [[ -z "$src" || "$src" != *:* ]] && { echo "用法: cctake <session>:<window>（如 product:1）"; return 1; }
  command tmux has-session -t ccbot 2>/dev/null || { echo "❌ 没有 ccbot session"; return 1; }
  local wid=$(command tmux list-windows -t "${src%%:*}" -F '#{window_id} #{window_index} #{window_name}' \
              | awk -v w="${src#*:}" '{n=$0; sub(/^[^ ]+ [^ ]+ /,"",n)} $2==w||n==w{print $1;exit}')
  [[ -z "$wid" ]] && { echo "❌ 找不到窗口 $src"; return 1; }
  command tmux move-window -s "$src" -t ccbot: || return 1
  _ccbot_rekey "$wid"
  _ccbot_pin_name "$wid" "${src%%:*}"   # 固定窗口名为源 session 名
  echo "✅ 已迁入 ccbot（$wid）。手机上在空 topic 发条消息 → 选择器选它接管。"
  if [[ -n "$TMUX" ]]; then
    command tmux switch-client -t ccbot \; select-window -t "$wid"
  else
    command tmux attach -t ccbot \; select-window -t "$wid"
  fi
}

# cclink <session>:<window>  把别的 tmux session 里的窗口「链接」进 ccbot（link，不搬走），
# 原 session 照旧可用（同一进程双向同步）。适合「session 为主、按需暴露给手机」。
# ⚠️ 用完必须在 Telegram 里 /unbind，切勿「关闭话题」：关话题会触发 CCBot 的 kill-window，
#    连你原 session 里的共享窗口一起销毁。桌面侧解绑：tmux unlink-window -t ccbot:<wid>。
# 边界：若之后在该窗口 /clear 或重启 claude，hook 可能重记回原前缀，需再跑一次 cclink。
cclink() {
  local src="$1"
  [[ -z "$src" || "$src" != *:* ]] && { echo "用法: cclink <session>:<window>（如 product:1）"; return 1; }
  command tmux has-session -t ccbot 2>/dev/null || { echo "❌ 没有 ccbot session"; return 1; }
  local wid=$(command tmux list-windows -t "${src%%:*}" -F '#{window_id} #{window_index} #{window_name}' \
              | awk -v w="${src#*:}" '{n=$0; sub(/^[^ ]+ [^ ]+ /,"",n)} $2==w||n==w{print $1;exit}')
  [[ -z "$wid" ]] && { echo "❌ 找不到窗口 $src"; return 1; }
  command tmux link-window -s "$src" -t ccbot: || return 1
  _ccbot_rekey "$wid"
  _ccbot_pin_name "$wid" "${src%%:*}"   # 固定窗口名为源 session 名（否则被 claude 版本号刷掉）
  echo "✅ 已链接进 ccbot（$wid），原 session 照旧可用。手机在空 topic 发消息 → 选择器选它接管。"
  echo "⚠️ 用完请在 Telegram /unbind（勿关话题）；桌面解绑: tmux unlink-window -t ccbot:$wid"
}

# ccspawn <name> [bot_token]  起一套独立的 CCBot 实例：一个群 = 一个 tmux session <name>。
# 机器侧全自动：CCBOT_DIR、.env、tmux session（含 set-environment 让 hook 写对目录）、
# launchd 服务。Telegram 侧需你手动：建 bot（BotFather）、建群开 Topics、拉 bot 进群设管理员、
# 开 Threaded Mode + 关 Privacy。给了 token 就直接启动，没给就打印补齐步骤。
ccspawn() {
  local name="$1" token="$2"
  [[ -z "$name" ]] && { echo "用法: ccspawn <name> [bot_token]"; return 1; }
  [[ "$name" == *[!A-Za-z0-9_-]* ]] && { echo "❌ name 只能含字母数字、_、-（不能有 . : / 空格等）"; return 1; }
  local dir="$HOME/.ccbot-$name" uid=$(id -u)
  local label="com.larryli.ccbot-$name"
  local plist="$HOME/Library/LaunchAgents/$label.plist"

  # tmux session：预建 + 设 CCBOT_DIR，使该 session 里 claude 的 hook 写进本实例目录
  command tmux has-session -t "$name" 2>/dev/null || command tmux new-session -d -s "$name" -n __main__
  command tmux set-environment -t "$name" CCBOT_DIR "$dir"

  mkdir -p "$dir"
  if [[ ! -f "$dir/.env" ]]; then
    cat > "$dir/.env" <<EOF
TELEGRAM_BOT_TOKEN=${token:-PUT_YOUR_BOT_TOKEN_HERE}
ALLOWED_USERS=8653795662
TMUX_SESSION_NAME=$name
CLAUDE_COMMAND=$HOME/.ccbot/claude-worktree.sh
EOF
    chmod 600 "$dir/.env"
  fi

  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$HOME/.local/bin/ccbot</string></array>
  <key>EnvironmentVariables</key><dict>
    <key>PATH</key><string>/opt/homebrew/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>CCBOT_DIR</key><string>$dir</string>
  </dict>
  <key>WorkingDirectory</key><string>$HOME</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$dir/bot.log</string>
  <key>StandardErrorPath</key><string>$dir/bot.err.log</string>
</dict></plist>
EOF

  echo "✅ 机器侧就绪：tmux session '$name' · $dir · launchd $label"
  if [[ -n "$token" ]]; then
    launchctl bootout "gui/$uid/$label" 2>/dev/null
    launchctl bootstrap "gui/$uid" "$plist" && echo "✅ 守护进程已启动（tail -f $dir/bot.err.log 看日志）"
  else
    echo "⚠️ 未提供 token。去 @BotFather 建 bot 后："
    echo "   1) 填 $dir/.env 的 TELEGRAM_BOT_TOKEN"
    echo "   2) launchctl bootstrap gui/$uid \"$plist\""
  fi
  echo "📱 Telegram 侧（手动）：新建群 → 开 Topics → 拉 bot 进群设管理员 → BotFather 开 Threaded Mode + 关 Privacy"
}
