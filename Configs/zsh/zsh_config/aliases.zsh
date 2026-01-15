alias cat='bat --paging=never'
alias fk=thefuck
alias nv='nvim'
alias v='nvim'
alias vim='nvim'
alias gitalias='alias | grep git | fzf'
alias gitalias='alias | rg git | fzf'

#alias git
alias fgcot='gco $(g tag | fzf)'
alias fgco='gco $(gb | fzf)'
alias fgcor='gco --track $(gbr | fzf)'

# alias general use
alias ls='eza --icons'                                                          # ls
alias l='eza -lbF --git --icons'                                                # list, size, type, git
alias ll='eza -lbGF --git --icons'                                             # long list
alias llm='eza -lbGd --git --sort=modified --icons'                            # long list, modified date sort
alias la='eza -lbhHigUmuSa --time-style=long-iso --git --color-scale --icons'  # all list
alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --icons' # all + extended list

# alias specialty views
alias lS='eza -1 --icons'                                                              # one column, just names
alias lt='eza --tree --level=3 --icons'                                         # tree
alias llt='eza -l --git --icons --tree '                                         # tree
alias lld='eza -lbhHFGmuSa --group-directories-first --icons'

# alias lazygit/lazydocker
alias lg=lazygit
alias ld=lazydocker
# alias tmux
alias mux="tmuxinator"

# petersen alias 
alias cenv="$WORK_PROJECT/changeenvironment.sh"
alias openApk='open "${WORK_PROJECT}/ar-petersen-cdp/mobile/platforms/android/app/build/outputs/apk/debug/"'
if [[ $(hostname) == "Lenins-MacBook-Pro.local" ]]; then
    export DOCKER_HOST='unix:///var/folders/p9/pldrp6g96lb22zk1hyd9mtc00000gn/T/podman/podman-machine-default-api.sock'
else
    export DOCKER_HOST='unix:///var/folders/86/mgwc95vs10q6h_6kmw33cnnw0000gp/T/podman/podman-machine-default-api.sock'
fi
alias docker=podman
alias nvcs='rm -rf ~/.local/state/nvim/sessions'
