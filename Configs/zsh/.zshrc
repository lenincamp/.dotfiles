# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="lambda"
# ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#586e75'

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
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



# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export EDITOR="nvim"
export VISUAL=$EDITOR

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
export FZF_DEFAULT_OPTS='--layout=reverse --no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window=up:85%:nowrap --layout=reverse --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-k:preview-up,ctrl-j:preview-down,ctrl-n:down,ctrl-p:up'"
if [[ $FIND_IT_FASTER_ACTIVE -eq 1 ]]; then
   FZF_DEFAULT_OPTS='--no-height --layout=reverse --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-k:preview-up,ctrl-j:preview-down,ctrl-n:down,ctrl-p:up''
fi


export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export ANDROID_HOME=~/Documents/projects/petersen/DevTools/Android/sdk # Ruta descrita en “Android SDK Location” en el paso anterior
export ANDROID_SDK_ROOT=~/Documents/projects/petersen/DevTools/Android/sdk # Ruta descrita en “Android SDK Location” en el paso anterior
# export JAVA_HOME=/Users/lcampoverde/Library/Java/JavaVirtualMachines/azul-17.0.10/Contents/Home
# export CORDOVA_JAVA_HOME=/Users/lcampoverde/Library/Java/JavaVirtualMachines/azul-17.0.10/Contents/Home
export JAVA_HOME=/opt/homebrew/Cellar/openjdk/23.0.2/libexec/openjdk.jdk/Contents/Home
export CORDOVA_JAVA_HOME=/opt/homebrew/Cellar/openjdk/23.0.2/libexec/openjdk.jdk/Contents/Home


export PATH=$PATH:$ANDROID_HOME/platform-tools/
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin/ # Validar que exista la carpeta latest previamente
export PATH=$PATH:$ANDROID_HOME/build-tools
export PATH=$PATH:$ANDROID_HOME/emulator/

alias nv='nvim'
alias v='nvim'
alias vim='nvim'
alias gitalias='alias | grep git | fzf'
alias cd=z


alias fgcot='gco $(g tag | fzf)'
alias fgco='gco $(gb | fzf)'
alias fgcor='gco --track $(gbr | fzf)'

# general use
alias ls='eza --icons'                                                          # ls
alias l='eza -lbF --git --icons'                                                # list, size, type, git
alias ll='eza -lbGF --git --icons'                                             # long list
alias llm='eza -lbGd --git --sort=modified --icons'                            # long list, modified date sort
alias la='eza -lbhHigUmuSa --time-style=long-iso --git --color-scale --icons'  # all list
alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --icons' # all + extended list

# specialty views
alias lS='eza -1 --icons'                                                              # one column, just names
alias lt='eza --tree --level=2 --icons'                                         # tree
alias llt='eza -l --git --icons --tree '                                         # tree
alias lld='eza -lbhHFGmuSa --group-directories-first --icons'

#petersen
export WORK_PROJECT='/Users/lcampoverde/Documents/projects/petersen'
alias cenv='$WORK_PROJECT/apache-tomcat-9.0.68/shared/changeenvironment.sh'
alias openApk='open $WORK_PROJECT/ar-petersen-cdp/mobile/platforms/android/app/build/outputs/apk/debug/'

### funcions
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
  logPath=~/Documents/projects/petersen/apache-tomcat-9.0.68/shared/shared_"$name"/omnichannel.log
  zed $logPath
}

function getIP() {
  ifconfig en0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | pbcopy
}

function buildApp(){
  jenv shell 17.0.10
  pyenv shell 2.7.18
  fnm use v14.21.3
  cd ~/Documents/projects/petersen/ar-petersen-cdp/mobile
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

#Open adroid emulator
function openAdv() {
  $ANDROID_SDK_ROOT/emulator/emulator @Medium_Phone_API_34
}


# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey "^O" fzf-cd-widget

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

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-min-size 80 12

# Shell integrations
eval "$(fnm env --use-on-cd)"
eval "$(starship init zsh)"
eval "$(pyenv init -)"
eval "$(jenv init -)"
export PATH="$HOME/.jenv/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/Documents/projects/petersen/instantclient/:$PATH"
# test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
