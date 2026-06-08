-- sonarlint.nvim: on-demand static analysis for Java (and other languages).
-- NOT auto-started — must be explicitly enabled with <leader>uS.
-- Uses the sonarlint-language-server from Mason (main nvim install).

local mason_sonar = vim.fn.expand("~/.local/share/nvim/mason/bin/sonarlint-language-server")

-- Only configure if the server binary is available
if vim.fn.filereadable(mason_sonar) == 0 then
  vim.notify("sonarlint-language-server not found. Run :MasonInstall sonarlint-language-server", vim.log.levels.WARN)
  return
end

local M = {}

local function enable_sonarlint()
  local ok, sonarlint = pcall(require, "sonarlint")
  if not ok then
    vim.notify("sonarlint.nvim not available", vim.log.levels.ERROR)
    return
  end

  sonarlint.setup({
    server = {
      cmd = { mason_sonar, "-stdio" },
    },
    filetypes = {
      "java",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "python",
    },
  })

  -- Attach to the current buffer immediately
  vim.cmd("LspStart sonarlint")
  vim.notify("SonarLint enabled", vim.log.levels.INFO)
  M.enabled = true
end

local function disable_sonarlint()
  vim.cmd("LspStop sonarlint")
  vim.notify("SonarLint disabled", vim.log.levels.INFO)
  M.enabled = false
end

M.enabled = false

-- Toggle keymap: <leader>uS — consistent with other <leader>u toggles
local ok_s, Snacks = pcall(require, "snacks")
if ok_s and Snacks.toggle then
  Snacks.toggle({
    name = "SonarLint",
    get  = function() return M.enabled end,
    set  = function(v)
      if v then enable_sonarlint() else disable_sonarlint() end
    end,
  }):map("<leader>uS")
else
  -- Fallback simple toggle
  vim.keymap.set("n", "<leader>uS", function()
    if M.enabled then disable_sonarlint() else enable_sonarlint() end
  end, { desc = "Toggle SonarLint" })
end
