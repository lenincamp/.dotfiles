############################ Shell integrations ###########################
eval "$(fnm env --use-on-cd)"
eval "$(starship init zsh)"
eval "$(pyenv init -)"
eval "$(jenv init -)"
export ZOXIDE_CMD_OVERRIDE="cd"
eval "$(zoxide init zsh)"
