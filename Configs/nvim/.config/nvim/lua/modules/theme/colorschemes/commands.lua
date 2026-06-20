local M = {}

local function current_theme(default)
  return vim.g.pure_colorscheme or vim.g.colors_name or default
end

local function theme_completion(themes)
  return vim.tbl_map(function(item)
    return item.key
  end, themes or {})
end

local function set_iterm_test_globals(enabled)
  local previous = {
    force = vim.g.pure_iterm2_sync_always,
    notify = vim.g.pure_iterm2_sync_notify,
    cache = vim.g._pure_iterm2_primary_last,
  }

  vim.g.pure_iterm2_sync_always = enabled
  vim.g.pure_iterm2_sync_notify = enabled
  vim.g._pure_iterm2_primary_last = nil

  return previous
end

local function restore_iterm_test_globals(previous)
  vim.g.pure_iterm2_sync_always = previous.force
  vim.g.pure_iterm2_sync_notify = previous.notify
  vim.g._pure_iterm2_primary_last = previous.cache
end

local function setup_iterm_commands(ctx)
  local function test_iterm_colors(opts)
    local theme = vim.trim(opts.args or "")
    if theme == "" then
      theme = current_theme(ctx.default)
    end

    local previous = set_iterm_test_globals(true)
    local ok = ctx.tool_sync.sync_iterm2_theme(theme)
    restore_iterm_test_globals(previous)

    vim.notify(
      string.format("ItermColorTest: theme=%s applied=%s", theme, tostring(ok == true)),
      ok and vim.log.levels.INFO or vim.log.levels.WARN
    )
  end

  vim.api.nvim_create_user_command("ItermColorTest", test_iterm_colors, {
    nargs = "?",
    desc = "Test iTerm2 background/foreground sync",
    complete = function()
      return theme_completion(ctx.themes)
    end,
    force = true,
  })

  vim.api.nvim_create_user_command("ItermPresetTest", test_iterm_colors, {
    nargs = "?",
    desc = "Deprecated alias for ItermColorTest",
    force = true,
  })
end

local function setup_tmux_command(ctx)
  vim.api.nvim_create_user_command("TmuxSync", function()
    vim.g._pure_tmux_theme_last = nil
    local theme = current_theme(ctx.default)
    ctx.tool_sync.sync_tmux_theme(theme)
    local result = vim.fn.system({ "tmux", "show-option", "-gqv", "@tmux_theme" })
    vim.notify("TmuxSync: theme=" .. theme .. " -> tmux @tmux_theme=" .. vim.trim(result), vim.log.levels.INFO)
  end, { desc = "Force tmux theme sync", force = true })
end

function M.setup(ctx)
  setup_iterm_commands(ctx)
  setup_tmux_command(ctx)
end

return M
