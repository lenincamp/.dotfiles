local APP_SUPPORT_PATH="$HOME/Library/Application Support"
local CONFIG_PATH="$HOME/.config/"
local BTOP_CONF=$(readlink "$CONFIG_PATH/btop/btop.conf")
local STARSHIP_CONF=$(readlink "$CONFIG_PATH/starship.toml")
local LAZYDOCKER_PATH="$APP_SUPPORT_PATH/lazydocker"
local EZA_PATH="$CONFIG_PATH/eza"

_resolve_lazygit_base() {
    local c1="$HOME/.dotfiles/Configs/lazygit/Library/Application Support/lazygit"
    local c2="$HOME/Library/Application Support/lazygit"

    [[ -d "$c1" ]] && { echo "$c1"; return 0; }
    [[ -d "$c2" ]] && { echo "$c2"; return 0; }
    echo "$c1"
}

_resolve_nvim_theme_state() {
    local c1="$HOME/.local/state/nvim/colorscheme.json"

    [[ -r "$c1" ]] && { echo "$c1"; return 0; }
    return 1
}

_resolve_nvim_theme_sync() {
    local c1="$HOME/.cache/nvim/theme-sync.zsh"

    [[ -f "$c1" ]] && { echo "$c1"; return 0; }
    return 1
}

_pure_refresh_theme_runtime() {
    local _state_path
    _state_path=$(_resolve_nvim_theme_state 2>/dev/null)
    if [[ -n "$_state_path" && -r "$_state_path" ]]; then
        local _k
        _k=$(sed -n 's/.*"key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_state_path" | head -n 1)
        if [[ -n "$_k" ]]; then
            local _base
            _base=$(_resolve_lazygit_base)
            local _generated="$_base/config-generated-${_k}.yml"
            if [[ -f "$_generated" ]]; then
                export LG_CONFIG_FILE="$_generated"
                return 0
            fi
        fi
    fi

    local _sync_path
    _sync_path=$(_resolve_nvim_theme_sync 2>/dev/null)
    if [[ -n "$_sync_path" && -f "$_sync_path" ]]; then
        source "$_sync_path"
        return 0
    fi

    local _latest=""
    local _base1="$HOME/.dotfiles/Configs/lazygit/Library/Application Support/lazygit"
    local _base2="$HOME/Library/Application Support/lazygit"
    local -a _generated_candidates
    _generated_candidates=("$_base1"/config-generated-*.yml(N) "$_base2"/config-generated-*.yml(N))
    if (( ${#_generated_candidates[@]} > 0 )); then
        _latest=$(/bin/ls -t -- "${_generated_candidates[@]}" 2>/dev/null | head -n 1)
    fi
    if [[ -n "$_latest" && -f "$_latest" ]]; then
        export LG_CONFIG_FILE="$_latest"
        return 0
    fi
}

# Backward-compatible helper name used by diagnostics/scripts.
_pure_refresh_lazygit_env() {
    _pure_refresh_theme_runtime "$@"
}

# Neovim writes theme-sync files, but it cannot mutate the parent shell env.
# Refresh right before launching lazygit to avoid a one-theme delay.
if [[ "${PURE_THEME_AUTHORITY:-nvim}" == "nvim" ]]; then
    lazygit() {
        _pure_refresh_theme_runtime
        command lazygit "$@"
    }
fi

local LAZYGIT_PATH=$(_resolve_lazygit_base)
local NVIM_THEME_STATE=$(_resolve_nvim_theme_state 2>/dev/null)
local NVIM_THEME_SHELL_SYNC=$(_resolve_nvim_theme_sync 2>/dev/null)

: "${PURE_THEME_AUTHORITY:=nvim}"

# Neovim is the source of truth.
# If Neovim has persisted theme state, do not run legacy shell-side sync logic.
if [[ "$PURE_THEME_AUTHORITY" == "nvim" ]]; then
    if [[ -n "$NVIM_THEME_SHELL_SYNC" && -f "$NVIM_THEME_SHELL_SYNC" ]]; then
        source "$NVIM_THEME_SHELL_SYNC"
        return 0
    fi

    # Fallback: no generated shell sync yet, but keep Neovim authority and avoid invalid exports.
    if [[ -n "$NVIM_THEME_STATE" && -r "$NVIM_THEME_STATE" ]]; then
        local _k
        _k=$(sed -n 's/.*"key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$NVIM_THEME_STATE" | head -n 1)
        if [[ -n "$_k" ]]; then
            local _generated="$LAZYGIT_PATH/config-generated-${_k}.yml"
            if [[ -f "$_generated" ]]; then
                export LG_CONFIG_FILE="$_generated"
            fi
        fi
    fi
    return 0
fi

_nvim_theme_key_from_state() {
    [[ -r "$NVIM_THEME_STATE" ]] || return 1
    sed -n 's/.*"key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$NVIM_THEME_STATE" | head -n 1
}

_mode_from_theme_key() {
    local key="$1"
    case "$key" in
        *latte*|*light*|*dawn*|*lotus*|*day*)
            echo "light"
            ;;
        *)
            echo "dark"
            ;;
    esac
}

local NVIM_THEME_KEY=""
if [[ "$PURE_THEME_AUTHORITY" == "nvim" ]]; then
    NVIM_THEME_KEY=$(_nvim_theme_key_from_state)
fi

local THEME_MODE=$(get_system_theme)
if [[ -n "$NVIM_THEME_KEY" ]]; then
    THEME_MODE=$(_mode_from_theme_key "$NVIM_THEME_KEY")
fi

if [[ "$THEME_MODE" == "dark" ]]; then
    source $ZSH/custom/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
    export BAT_THEME="Catppuccin Mocha"
    local THEME="catppuccin_mocha"
    export FZF_DEFAULT_OPTS="--layout=reverse --no-height --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --color=border:#313244,label:#cdd6f4"
    local ZELLIJ_THEME="catppuccin-macchiato"
    local LD_SRC="$LAZYDOCKER_PATH/config-dark.yml"
else
    source $ZSH/custom/themes/catppuccin_latte-zsh-syntax-highlighting.zsh
    export BAT_THEME="Catppuccin Latte"
    local THEME="catppuccin_latte"
    export FZF_DEFAULT_OPTS="--layout=reverse --no-height --color=bg+:#e6e9ef,bg:#eff1f5,spinner:#515c7a,hl:#ea76cb --color=fg:#4c4f69,header:#ea76cb,info:#8839ef,pointer:#515c7a --color=marker:#1e66f5,fg+:#4c4f69,prompt:#8839ef,hl+:#ea76cb --color=selected-bg:#ccd0da --color=border:#e6e9ef,label:#4c4f69"
    local ZELLIJ_THEME="catppuccin-latte"
    local LD_SRC="$LAZYDOCKER_PATH/config-light.yml"
fi

# Neovim is the source of truth for synced tool themes.
# If we have a persisted Neovim theme key, prefer the generated lazygit config.
if [[ -n "$NVIM_THEME_KEY" ]]; then
    local _nvim_generated_lazygit="$LAZYGIT_PATH/config-generated-${NVIM_THEME_KEY}.yml"
    if [[ -f "$_nvim_generated_lazygit" ]]; then
        export LG_CONFIG_FILE="$_nvim_generated_lazygit"
    fi
fi

# Fallback if Neovim-generated lazygit config is not available yet.
if [[ -z "$LG_CONFIG_FILE" ]]; then
    local _fallback_dark="$LAZYGIT_PATH/config.yml"
    local _fallback_light="$LAZYGIT_PATH/config-light.yml"
    if [[ "$THEME_MODE" == "dark" && -f "$_fallback_dark" ]]; then
        export LG_CONFIG_FILE="$_fallback_dark"
    elif [[ "$THEME_MODE" != "dark" && -f "$_fallback_light" ]]; then
        export LG_CONFIG_FILE="$_fallback_light"
    elif [[ -f "$_fallback_dark" ]]; then
        export LG_CONFIG_FILE="$_fallback_dark"
    elif [[ -f "$_fallback_light" ]]; then
        export LG_CONFIG_FILE="$_fallback_light"
    fi
fi

cp "$LD_SRC" "$LAZYDOCKER_PATH/config.yml"
# Keep zsh startup cheap and avoid overriding Neovim-synced files.
# - eza theme.yml is generated by Neovim
# - starship.toml palette/styles are generated by Neovim
# - lazygit is selected above via generated config when available

if [[ -n "$BTOP_CONF" && -f "$BTOP_CONF" ]]; then
    sed -i '' "s/color_theme = \".*\"/color_theme = \"$THEME\"/" "$BTOP_CONF"
fi

local ZELLIJ_CONF=$(readlink "$CONFIG_PATH/zellij/config.kdl")
if [[ -n "$ZELLIJ_CONF" && -f "$ZELLIJ_CONF" ]]; then
    sed -i '' "s/theme \".*\"/theme \"$ZELLIJ_THEME\"/" "$ZELLIJ_CONF"
    touch "$HOME/.config/zellij/config.kdl"
fi

# zle reset-prompt
