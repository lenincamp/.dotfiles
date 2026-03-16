alias cat='bat --paging=never'
alias fk=thefuck
alias nv='nvim'
alias v='nvim'
alias vim='nvim'
alias gitalias='alias | rg git | fzf'

#alias git
alias fgcot='gco $(g tag | fzf)'
alias fgco='gco $(gb | fzf)'
alias fgcor='gco --track $(gbr | fzf)'

# ls (base)
alias ls='eza --icons --git --group-directories-first'              # drop-in ls replacement: icons, git status, dirs first
alias l='eza -1 --icons --group-directories-first'                  # compact single-column list
alias ll='eza -lah --git --icons --group-directories-first'         # long list: permissions, size, date, git status
alias la='eza -lah --all --git --icons --group-directories-first'   # like ll but includes hidden files (dotfiles)
alias lr='eza -lah --sort=modified --reverse --git --icons'         # newest files first — handy after a build or git pull
# sorting
alias lm='eza -lah --sort=modified --git --icons'                   # sort by modification date, oldest first
alias lsiz='eza -lah --sort=size --git --icons --color-scale'       # sort by size with color gradient — spot heavy files fast
alias le='eza -lah --sort=extension --git --icons'                  # sort by extension — groups same file types together
# tree
alias lt='eza --tree --level=2 --icons'                             # 2-level tree — quick structure overview
alias lt3='eza --tree --level=3 --icons'                            # 3-level tree — deeper subfolder detail
alias llt='eza --tree -lah --git --icons'                           # tree with full details and git status
# git (lg and ld reserved for lazygit/lazydocker)
alias lgi='eza -lah --git --git-repos --icons'                      # shows git repo status per subfolder — useful in monorepos
alias lgs='eza -lah --git --icons --sort=status'                    # group by git status: modified, new, ignored
# debug
alias lx='eza -lah@ --git --icons --time-style=long-iso'            # includes extended attributes (xattrs) and full ISO date
alias li='eza -lai --icons'                                         # shows inode number — useful to detect hardlinks
# utilities
alias ld='eza -lD --icons'                                        # directories only
alias lf='eza -lf --icons'                                          # files only (no directories)
alias lbig='eza -lah --sort=size --git --icons | head -20'          # top 20 heaviest files in the directory
alias llink='eza -lah --git --icons --classify | rg " -> "'         # symlinks only — shows source and target
alias lexe='eza -lah --git --icons --classify | rg "[*]"'           # executables only
alias ltree='eza --tree --level=2 --icons --git-ignore'             # tree respecting .gitignore — skips node_modules, dist, etc.
alias lrecent='eza -lah --sort=modified --reverse --git --icons | head -20' # 20 most recently modified files

# alias lazygit/lazydocker
alias lg=lazygit
alias ldoc=lazydocker
# alias tmux
alias mux="tmuxinator"

# petersen alias 
alias cenv="$WORK_PROJECT/changeenvironment.sh"
# alias openApk='open "${WORK_PROJECT}/ar-petersen-cdp/mobile/platforms/android/app/build/outputs/apk/debug/"'
alias openApk='open "${HOME}/workspace/projects/patagonia/ar-patagonia-cdp/frontend/apps/mobile/platforms/android/app/build/outputs/apk/debug/"'
if [[ $(hostname) == "Lenins-MacBook-Pro.local" ]]; then
    export DOCKER_HOST='unix:///var/folders/p9/pldrp6g96lb22zk1hyd9mtc00000gn/T/podman/podman-machine-default-api.sock'
else
    export DOCKER_HOST='unix:///var/folders/86/mgwc95vs10q6h_6kmw33cnnw0000gp/T/podman/podman-machine-default-api.sock'
fi
alias docker=podman
alias nvcs='rm -rf ~/.local/state/nvim/sessions'
alias nvpcs='rm -rf ~/.local/state/nvim-pure/sessions'
alias vv='NVIM_APPNAME=nvim-pure nvim'
