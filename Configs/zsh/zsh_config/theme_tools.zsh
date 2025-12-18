local APP_SUPPORT_PATH="$HOME/Library/Application Support"
local CONFIG_PATH="$HOME/.config/"
local BTOP_CONF=$(readlink "$CONFIG_PATH/btop/btop.conf")
local STARSHIP_CONF=$(readlink "$CONFIG_PATH/starship.toml")
local LAZYGIT_PATH="$APP_SUPPORT_PATH/lazygit"
local LAZYDOCKER_PATH="$APP_SUPPORT_PATH/lazydocker"
local EZA_PATH="$CONFIG_PATH/eza"

local THEME_MODE=$(get_system_theme)
if [[ "$THEME_MODE" == "dark" ]]; then
    source $ZSH/custom/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
    export BAT_THEME="Catppuccin Mocha"
    export LG_CONFIG_FILE="$LAZYGIT_PATH/config.yml"
    local THEME="catppuccin_mocha"
    export FZF_DEFAULT_OPTS="--layout=reverse --no-height --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --color=border:#313244,label:#cdd6f4"
    local ZELLIJ_THEME="catppuccin-macchiato"
    local LD_SRC="$LAZYDOCKER_PATH/config-dark.yml"
    local EZA_SRC="$EZA_PATH/config-dark.yml"
else
    source $ZSH/custom/themes/catppuccin_latte-zsh-syntax-highlighting.zsh
    export BAT_THEME="Catppuccin Latte"
    export LG_CONFIG_FILE="$LAZYGIT_PATH/config-light.yml"
    local THEME="catppuccin_latte"
    export FZF_DEFAULT_OPTS="--layout=reverse --no-height --color=bg+:#e6e9ef,bg:#eff1f5,spinner:#515c7a,hl:#ea76cb --color=fg:#4c4f69,header:#ea76cb,info:#8839ef,pointer:#515c7a --color=marker:#1e66f5,fg+:#4c4f69,prompt:#8839ef,hl+:#ea76cb --color=selected-bg:#ccd0da --color=border:#e6e9ef,label:#4c4f69"
    local ZELLIJ_THEME="catppuccin-latte"
    local LD_SRC="$LAZYDOCKER_PATH/config-light.yml"
    local EZA_SRC="$EZA_PATH/config-light.yml"
fi
cp "$LD_SRC" "$LAZYDOCKER_PATH/config.yml"
cp "$EZA_SRC" "$EZA_PATH/theme.yml"
sed -i '' "s/color_theme = \".*\"/color_theme = \"$THEME\"/" "$BTOP_CONF"
sed -i '' "s/palette = \".*\"/palette = \"$THEME\"/" "$STARSHIP_CONF"
sed -i '' "s/theme \".*\"/theme \"$ZELLIJ_THEME\"/" $(readlink "$CONFIG_PATH/zellij/config.kdl")
touch "$HOME/.config/zellij/config.kdl"

# zle reset-prompt
