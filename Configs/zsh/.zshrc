export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="lambda"
plugins=(
        git
        zsh-vi-mode
        z
        fzf
        fzf-tab
        docker
        zsh-syntax-highlighting
        zsh-autosuggestions
)
source $ZSH/oh-my-zsh.sh

######################## ALIASES ###############################
alias cat='bat --paging=never'
alias fk=thefuck
alias nv='nvim'
alias v='nvim'
alias vim='nvim'
alias gitalias='alias | grep git | fzf'
alias cd=z

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
alias lt='eza --tree --level=2 --icons'                                         # tree
alias llt='eza -l --git --icons --tree '                                         # tree
alias lld='eza -lbhHFGmuSa --group-directories-first --icons'

# alias lazygit/lazydocker
alias lg=lazygit
alias ld=lazydocker

# petersen alias 
alias cenv="$WORK_PROJECT/apache-tomcat-9.0.68/shared/changeenvironment.sh"
alias openApk="open $WORK_PROJECT/ar-petersen-cdp/mobile/platforms/android/app/build/outputs/apk/debug/"

################################# Funcions ###################################
#fuzzy docker start
function fdstart() {
	CONTAINER=`docker ps -a | rg -v CONTAINER | awk '-F ' ' {print $NF}' | fzf`
	if [ ! -z $CONTAINER ]
	then
		docker start $CONTAINER
	fi
}

#fuzzy docker stop
function fdstop() {
	CONTAINER=`docker ps | rg -v CONTAINER | awk '-F ' ' {print $NF}' | fzf`
	if [ ! -z $CONTAINER ]
	then
		docker stop $CONTAINER
	fi
}

#fuzzy docker exec
function fdex() {
	CONTAINER=`dclsa | rg -v CONTAINER | awk '-F ' ' {print $NF}' | fzf`
	if [ ! -z $CONTAINER ]
	then
		docker exec -it $CONTAINER bash
	fi
}

#fuzzy docker log
function fdlog() {
	CONTAINER=`docker ps | rg -v CONTAINER | awk '-F ' ' {print $NF}' | fzf`
	if [ ! -z $CONTAINER ]
	then
		docker logs -f $CONTAINER
	fi
}

#petersen logs
function tol() {
  name=$1
  name=${name:u}
  logPath=$WORK_PROJECT/apache-tomcat-9.0.68/shared/shared_"$name"/omnichannel.log
  zed $logPath
}

function getIP() {
  ifconfig en0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | pbcopy
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
## yazi file manager
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
######################################################################################

#Open adroid emulator
function openAdv() {
  $ANDROID_SDK_ROOT/emulator/emulator @Medium_Phone_API_34
}
#######################################################################################

###################################### Keybindings ####################################
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey "^O" fzf-cd-widget
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
export BAT_THEME="Catppuccin Mocha"

######### fzf #######
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
export FZF_DEFAULT_OPTS='--layout=reverse --no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'
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
export JAVA_HOME=/opt/homebrew/Cellar/openjdk/23.0.2/libexec/openjdk.jdk/Contents/Home
export CORDOVA_JAVA_HOME=/opt/homebrew/Cellar/openjdk/23.0.2/libexec/openjdk.jdk/Contents/Home

export PATH=$PATH:$ANDROID_HOME/platform-tools/
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin/ # Validar que exista la carpeta latest previamente
export PATH=$PATH:$ANDROID_HOME/build-tools
export PATH=$PATH:$ANDROID_HOME/emulator/
neofetch
