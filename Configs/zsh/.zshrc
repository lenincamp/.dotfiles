export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="lambda"
plugins=(
        git
        zsh-vi-mode
        zoxide
        fzf
        fzf-tab
        zsh-syntax-highlighting
        zsh-autosuggestions
)
source $ZSH/oh-my-zsh.sh
source <(fzf --zsh)
ZSH_FUNCTIONS_DIR="$HOME/zsh_functions"
fpath=(
    "$ZSH_FUNCTIONS_DIR/docker"
    "$ZSH_FUNCTIONS_DIR/salesforce"
    "$ZSH_FUNCTIONS_DIR/system"
    $fpath
)

######################## ALIASES ###############################
alias cat='bat --paging=never'
alias fk=thefuck
alias nv='nvim'
alias v='nvim'
alias vim='nvim'
alias gitalias='alias | grep git | fzf'

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
alias openApk="open $WORK_PROJECT/ar-petersen-cdp/mobile/platforms/android/app/build/outputs/apk/debug/"
if [[ $(hostname) == "Lenins-MacBook-Pro.local" ]]; then
    export DOCKER_HOST='unix:///var/folders/p9/pldrp6g96lb22zk1hyd9mtc00000gn/T/podman/podman-machine-default-api.sock'
    alias docker=podman
fi

################################# Funcions ###################################
#petersen logs
function tol() {
  name=$1
  name=${name:u}
  logPath=$WORK_PROJECT/apache-tomcat-9.0.68/shared/shared_"$name"/omnichannel.log
  zed $logPath
}

function buildApp(){
  jenv shell 17.0.10
  pyenv shell 2.7.18
  fnm use v14.21.3
  cd $WORK_PROJECT/ar-petersen-cdp/mobile
  if [ $# -eq 0 ] || [ -z "$1" -a -z "$2" ]; then
      python release.py lcampoverde --debug --no-ios --verbose
      exit 1
  fi
  if [ $1 = "--r" ]; then
        cd ../web
        yarn build
        cd ../mobile
  fi
  python release.py lcampoverde --debug $2 --verbose
  # Obtener la dirección IP de la máquina actual
  #   IP=$(ifconfig en0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
}
######################################################################################

#Open adroid emulator
function openAdv() {
  $ANDROID_SDK_ROOT/emulator/emulator @Medium_Phone_API_34
}
#######################################################################################
#Functions Lazy Load
autoload -U sfcov sfdiff sfl sfld sftr fdex fdlog fdstart fdstop get_system_theme get_system_ip y
###################################### Keybindings ####################################
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey "^O" fzf-cd-widget
unset LAST_LOGIN
#######################################################################################

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

############################ Shell integrations ###########################
eval "$(fnm env --use-on-cd)"
eval "$(starship init zsh)"
eval "$(pyenv init -)"
eval "$(jenv init -)"
export ZOXIDE_CMD_OVERRIDE="cd"
eval "$(zoxide init zsh)"

########################### PATH variables ################################
# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

local BTOP_CONF=$(readlink "$HOME/.config/btop/btop.conf")
local LAZYGIT_PATH="$HOME/Library/Application Support/lazygit"
local THEME_MODE=$(get_system_theme)
if [[ "$THEME_MODE" == "dark" ]]; then
    source $ZSH/custom/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
    export BAT_THEME="Catppuccin Mocha"
    export LG_CONFIG_FILE="$LAZYGIT_PATH/config.yml"
    local THEME="catppuccin_mocha"
else
    source $ZSH/custom/themes/catppuccin_latte-zsh-syntax-highlighting.zsh
    export BAT_THEME="Catppuccin Latte"
    export LG_CONFIG_FILE="$LAZYGIT_PATH/config-light.yml"
    local THEME="catppuccin_latte"
fi
sed -i '' "s/color_theme = \".*\"/color_theme = \"$THEME\"/" "$BTOP_CONF"
# zle reset-prompt


export LANG=en_US.UTF-8
export PATH="$HOME/.jenv/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
#petersen
export WORK_PROJECT="$HOME/workspace/projects/petersen"
export PATH="$WORK_PROJECT/instantclient/:$PATH"
#EZA
export EZA_CONFIG_DIR=$HOME/.config/eza
export EDITOR="nvim"
export VISUAL=$EDITOR

#bat theme - https://github.com/catppuccin/bat
# export BAT_THEME="Catppuccin Mocha"

######### fzf #######
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
export FZF_DEFAULT_OPTS="--layout=reverse --no-height --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --color=border:#313244,label:#cdd6f4"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window=up:85%:nowrap --layout=reverse --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-k:preview-up,ctrl-j:preview-down,ctrl-n:down,ctrl-p:up'"
if [[ $FIND_IT_FASTER_ACTIVE -eq 1 ]]; then
   FZF_DEFAULT_OPTS='--no-height --layout=reverse --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-k:preview-up,ctrl-j:preview-down,ctrl-n:down,ctrl-p:up''
fi
export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"
# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-min-size 80 12
#############################
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export ANDROID_HOME=$HOME/workspace/DevTools/Android/sdk # Ruta descrita en “Android SDK Location” en el paso anterior
export ANDROID_SDK_ROOT=$HOME/workspace/DevTools/Android/sdk # Ruta descrita en “Android SDK Location” en el paso anterior
# export JAVA_HOME=$HOME/Library/Java/JavaVirtualMachines/azul-17.0.10/Contents/Home
# export CORDOVA_JAVA_HOME=$HOME/Library/Java/JavaVirtualMachines/azul-17.0.10/Contents/Home
export JAVA_HOME=/opt/homebrew/Cellar/openjdk/25/libexec/openjdk.jdk/Contents/Home
export CORDOVA_JAVA_HOME=/opt/homebrew/Cellar/openjdk/25/libexec/openjdk.jdk/Contents/Home

export PATH=$PATH:$ANDROID_HOME/platform-tools/
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin/ # Validar que exista la carpeta latest previamente
export PATH=$PATH:$ANDROID_HOME/build-tools
export PATH=$PATH:$ANDROID_HOME/emulator/
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export XDG_DATA_DIRS="/opt/homebrew/share:$XDG_DATA_DIRS"
