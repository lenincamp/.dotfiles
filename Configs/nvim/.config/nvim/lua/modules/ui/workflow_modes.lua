local M = {}

local modes = {
  {
    key = "focus",
    label = "Focus",
    apply = function()
      vim.g.pure_ui_dim_enabled = true
      vim.diagnostic.config({ virtual_text = false })
      vim.o.wrap = false
      vim.o.ruler = false
      vim.o.showcmd = false
      vim.o.showmode = false
      require("modules.ui.zen").toggle_zen_mode()
    end,
  },
  {
    key = "review",
    label = "Review",
    apply = function()
      vim.diagnostic.config({ virtual_text = false })
      vim.o.wrap = false
      require("modules.editor.diff_mode").toggle_diff_profile()
      pcall(vim.cmd.copen)
    end,
  },
  {
    key = "debug",
    label = "Debug",
    apply = function()
      local runtime = require("modules.core.runtime")
      runtime.load_config("nvim-dap")
      runtime.load_config("nvim-dap-view")
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
  {
    key = "ai",
    label = "AI",
    apply = function()
      local runtime = require("modules.core.runtime")
      runtime.load_config("minuet")
      runtime.load_config("avante")
      runtime.load_config("render-markdown")
    end,
  },
  {
    key = "large-file",
    label = "Large File",
    apply = function()
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.foldenable = false
      vim.opt_local.list = false
      vim.opt_local.cursorline = false
      vim.diagnostic.enable(false, { bufnr = 0 })
      pcall(vim.treesitter.stop, 0)
    end,
  },
}

function M.select()
  require("modules.editor.picker").select_items(modes, {
    prompt = "Workflow Mode",
    scope = "global",
    search_threshold = 0,
    format_item = function(item) return item.label end,
  }, function(item)
    if item then
      item.apply()
      vim.notify("Workflow: " .. item.label, vim.log.levels.INFO, { title = "UI" })
    end
  end)
end

return M
