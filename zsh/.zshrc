# ── Node (fnm) ────────────────────────────────
eval "$(fnm env --use-on-cd --corepack-enabled)"

# ── PATH ──────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Directory ─────────────────────────────────
setopt AUTO_CD                # 直接输入目录名即可进入
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# ── History ───────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY          # 多终端共享历史
setopt HIST_IGNORE_ALL_DUPS   # 去重
setopt HIST_IGNORE_SPACE      # 空格开头的命令不记录（隐私）
setopt HIST_REDUCE_BLANKS     # 去除多余空格

# 前缀 + ↑/↓ 搜索历史（输入 "git" 再按 ↑ 只找 git 开头的命令）
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# ── Completion ────────────────────────────────
autoload -Uz compinit && compinit
setopt CORRECT                # 命令拼写纠错
zstyle ':completion:*' menu select                    # 方向键选择补全
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # 大小写不敏感

# ── Plugins ───────────────────────────────────
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── fzf ───────────────────────────────────────
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --info=inline
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# ── Zoxide (smart cd) ────────────────────────
eval "$(zoxide init zsh)"

# ── Aliases ───────────────────────────────────
source ~/.config/zsh/aliases.zsh

# ── Starship Prompt (must be last) ───────────
eval "$(starship init zsh)"
[[ -f ~/.iterm2_shell_integration.zsh ]] && source ~/.iterm2_shell_integration.zsh
