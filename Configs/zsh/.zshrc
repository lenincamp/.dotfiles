################################# Config Directories ###################################
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CONFIG_DIR="$HOME/zsh_config"
export ZSH_FUNCTIONS_DIR="$HOME/zsh_functions"

# Configurar fpath ANTES de cargar oh-my-zsh (compinit se ejecuta ahí)
if [ -d "$ZSH_FUNCTIONS_DIR" ]; then
    fpath=(
        "$ZSH_FUNCTIONS_DIR/docker"
        "$ZSH_FUNCTIONS_DIR/salesforce"
        "$ZSH_FUNCTIONS_DIR/system"
        "$ZSH_FUNCTIONS_DIR/sofi"
        $fpath
    )
else
    echo "⚠️  Warning: zsh_functions not found at $ZSH_FUNCTIONS_DIR"
fi

########################### PATH variables (EARLY) ################################
# Load PATH variables BEFORE oh-my-zsh so tools are available
if [ -f "$ZSH_CONFIG_DIR/path.zsh" ]; then
    source "$ZSH_CONFIG_DIR/path.zsh"
    # Verify Homebrew is in PATH
    if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
fi

################################# Oh-My-Zsh Setup #####################################
ZSH_THEME="lambda"
plugins=(
    git
    zsh-vi-mode
    fzf-tab
    zsh-syntax-highlighting
    zsh-autosuggestions
)

# zsh-vi-mode hook: rebind atuin AFTER vi-mode resets all keybindings
# zvm_after_init runs after zsh-vi-mode finishes initializing
function zvm_after_init() {
    export ATUIN_NOBIND="true"
    if command -v atuin &>/dev/null; then
        eval "$(atuin init zsh --disable-up-arrow)"
        bindkey '^r' atuin-search
        bindkey '^[[A' atuin-up-search
        bindkey '^[OA' atuin-up-search
    fi
}

source $ZSH/oh-my-zsh.sh

################################# Autoload Custom Functions ############################
# Oh-my-zsh ya ejecutó compinit, solo autoload las funciones
autoload -U sfcov sfdiff sfl sfld sftr sflso sfow fdex fdlog fdstart fdstop get_system_theme get_system_ip y openAdv 2>/dev/null

######################## ALIASES ###############################
[ -f "$ZSH_CONFIG_DIR/aliases.zsh" ] && source "$ZSH_CONFIG_DIR/aliases.zsh"

######################## THEME TOOLS ##########################
[ -f "$ZSH_CONFIG_DIR/theme_tools.zsh" ] && source "$ZSH_CONFIG_DIR/theme_tools.zsh"
#######################################################################################
###################################### Keybindings ####################################
# NOTE: atuin Ctrl+R bindings are set in zvm_after_init to prevent zsh-vi-mode from overriding them
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
[ -f "$ZSH_CONFIG_DIR/shell_integrations.zsh" ] && source "$ZSH_CONFIG_DIR/shell_integrations.zsh"
[ -f "$ZSH_CONFIG_DIR/lazy.zsh" ] && source "$ZSH_CONFIG_DIR/lazy.zsh"

# Re-apply atuin bindings last — fzf (sourced above) overrides ^r in viins
if zle -la 2>/dev/null | grep -q atuin-search; then
    bindkey -M viins '^r' atuin-search
    bindkey -M emacs '^r' atuin-search
    bindkey -M viins '^[[A' atuin-up-search
    bindkey -M viins '^[OA' atuin-up-search
fi


# Added by SoFi Claude Code installer
export PATH="$HOME/.local/bin:$PATH"

