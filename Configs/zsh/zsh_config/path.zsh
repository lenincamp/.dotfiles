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
# export BAT_THEME="Catppuccin Mocha"

######### fzf #######
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
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
