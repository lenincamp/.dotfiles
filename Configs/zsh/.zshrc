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
################################# Funcions ###################################
ZSH_FUNCTIONS_DIR="$HOME/zsh_functions"
fpath=(
    "$ZSH_FUNCTIONS_DIR/docker"
    "$ZSH_FUNCTIONS_DIR/salesforce"
    "$ZSH_FUNCTIONS_DIR/system"
    "$ZSH_FUNCTIONS_DIR/sofi"
    $fpath
)
#Functions Lazy Load
autoload -U sfcov sfdiff sfl sfld sftr sflso sfow fdex fdlog fdstart fdstop get_system_theme get_system_ip y buildApp openAdv tol
######################## ALIASES ###############################
local ZSH_CONFIG_DIR="$HOME/zsh_config"
local ALIASES="$ZSH_CONFIG_DIR/aliases.zsh"
if [ -f "$ALIASES" ]; then
    source "$ALIASES"
fi
local THEME_TOOLS="$ZSH_CONFIG_DIR/theme_tools.zsh"
if [ -f "$THEME_TOOLS" ]; then
    source "$THEME_TOOLS"
fi
#######################################################################################
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
local SHELL_INTEGRATIONS="$ZSH_CONFIG_DIR/shell_integrations.zsh"
if [ -f "$SHELL_INTEGRATIONS" ]; then
    source "$SHELL_INTEGRATIONS"
fi
########################### PATH variables ################################
local SETTINGS_PATH="$ZSH_CONFIG_DIR/path.zsh"
if [ -f "$SETTINGS_PATH" ]; then
    source "$SETTINGS_PATH"
fi
