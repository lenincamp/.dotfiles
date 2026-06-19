local M = {}

function M.opts_for_mode(mode)
  if mode == "light" then
    return "--layout=reverse --no-height --color=bg+:#e6e9ef,bg:#eff1f5,spinner:#515c7a,hl:#ea76cb --color=fg:#4c4f69,header:#ea76cb,info:#8839ef,pointer:#515c7a --color=marker:#1e66f5,fg+:#4c4f69,prompt:#8839ef,hl+:#ea76cb --color=selected-bg:#ccd0da --color=border:#e6e9ef,label:#4c4f69"
  end

  return "--layout=reverse --no-height --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --color=border:#313244,label:#cdd6f4"
end

return M
