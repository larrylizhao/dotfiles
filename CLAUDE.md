# dotfiles — AI agent 指南

larryli 的个人配置仓库。GNU Stow 风格管理,远程 `git@github.com:larrylizhao/dotfiles.git`。

## 架构(必须先理解)

每个顶层目录是一个 **stow 包**,其内部目录树镜像 `$HOME`:

```
~/dotfiles/
├── zsh/        → .zshrc, .config/zsh/aliases.zsh
├── git/        → .gitconfig
├── starship/   → .config/starship.toml
├── ghostty/    → Library/Application Support/com.mitchellh.ghostty/config.ghostty
└── tmux/       → .config/tmux/{tmux.conf,window-icon.sh}
```

`stow zsh` 会把 `zsh/` 下的文件**软链**到 `$HOME` 对应位置。所以:

> ⚠️ **编辑 `~/.config/tmux/tmux.conf`、`~/.zshrc` 等,改的就是本仓库文件**(它们是软链)。这是特性也是陷阱。

## 改配置时的约定

0. **改前先确认目标是软链**(`ls -l <路径>` 看有没有 `->`,或比 inode)。stow 可能只链了部分文件,残留的真实副本会和仓库**双向漂移**——表面正常(zsh 照常加载),实则你编辑/提交的是两个不同文件。曾发生:`~/.config/zsh/aliases.zsh` 是脱钩的真实副本,编辑生效但 `git` 看不到改动。修法:以真实文件为准合并进仓库 → `rm` 真实文件 → `ln -s` 回仓库(或 `stow` 重链)。
1. **直接编辑目标路径即可**(软链会落到仓库),或直接编辑仓库内文件——等价。
2. **生成物绝不入库**:插件、缓存、运行时数据。已在 `.gitignore` 排除(如 `tmux/.config/tmux/plugins/`)。新增工具若会在配置目录生成内容,先加 `.gitignore`(用仓库内真实路径,不是软链后的路径)。
3. **提交按语义分组**:一个逻辑改动一个 commit(例:`zsh: ...`、`git: ...`),不要一坨 "update configs"。
4. **commit 不自动 push**,等用户审阅。
5. 新配置优先纳入 dotfiles;但工具自动生成、含机器相关状态的(`gh`/`iterm2`/`raycast` 等)保持游离不纳管。

## 关键工具链

- **shell**: zsh + fnm(node)+ starship + fzf + zsh-autosuggestions/syntax-highlighting(brew)
- **terminal**: ghostty(Catppuccin Mocha 基础上自定义前/背景色)
- **tmux**: prefix `C-s`,Rosé Pine 状态栏;TPM 管理插件;resurrect+continuum 做 session 持久化(每 15min 自动存档、启动自动恢复、恢复 claude 带 `--continue`)。手动键:`prefix+r` reload、`prefix+S`/`prefix+R` 存/恢复。
- **nvim**: 四套 distro 经 `NVIM_APPNAME` 别名切换(`lazyvim`/`nvchad`/`astronvim`/`nvimdots`),均未纳管。

## 换新机恢复

```sh
git clone git@github.com:larrylizhao/dotfiles.git ~/dotfiles
cd ~/dotfiles
# 装 stow: brew install stow
stow zsh git starship ghostty tmux      # 软链各包到 $HOME
# tmux 插件(被 gitignore,需重新拉取):
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
# 进 tmux 后按 prefix(C-s) + I 安装 resurrect/continuum
```
依赖:`brew install stow fnm starship fzf tmux zsh-autosuggestions zsh-syntax-highlighting`
