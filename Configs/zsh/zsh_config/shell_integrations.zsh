############################ Shell integrations ###########################
# Cache directory for eval outputs
_ZSH_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$_ZSH_CACHE" ]] || mkdir -p "$_ZSH_CACHE"

# _cache_eval <name> <cmd> [args...]
# Sources cached init script; regenerates only when the binary changes
_cache_eval() {
    local name="$1"; shift
    local bin
    bin=$(command -v "$1" 2>/dev/null) || return
    local cache="$_ZSH_CACHE/${name}.zsh"
    if [[ ! -f "$cache" || "$bin" -nt "$cache" ]]; then
        "$@" > "$cache"
    fi
    source "$cache"
}

# FNM (Fast Node Manager) — session-specific paths, cannot be cached
if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# Starship prompt
command -v starship &>/dev/null && _cache_eval starship starship init zsh

# Zoxide (cd replacement)
export ZOXIDE_CMD_OVERRIDE="cd"
command -v zoxide &>/dev/null && _cache_eval zoxide zoxide init zsh

# FZF shell integration (keybindings + completion)
command -v fzf &>/dev/null && _cache_eval fzf fzf --zsh
