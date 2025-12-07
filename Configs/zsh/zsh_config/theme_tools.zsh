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
