-- Tests: Neotest (JS) · java.lua (Maven) · salesforce.nvim (Apex)
-- Keys: tn nearest · tf file · td debug · tl last · tw watch

local M = {}

local setup_done = false
local last_run
local watch_enabled = false
local watch_group = "pure_test_watch"

local WATCH_FILETYPES = {
  java = true,
  apex = true,
  javascript = true,
  typescript = true,
  javascriptreact = true,
  typescriptreact = true,
}

local function project_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] then
    return out[1]
  end
  return vim.fn.getcwd()
end

local function ensure_neotest()
  pcall(function()
    require("lazy").load({ plugins = { "neotest" } })
  end)
  if setup_done then
    return
  end
  setup_done = true
  require("neotest").setup({
    adapters = {
      require("neotest-vitest")({ cwd = project_root }),
      require("neotest-jest")({
        cwd = project_root,
        jestCommand = "npm test --",
      }),
    },
    output = { open_on_run = "short" },
    status = { virtual_text = true },
  })
end

local function disable_watch()
  watch_enabled = false
  pcall(vim.api.nvim_del_augroup_by_name, watch_group)
end

local function enable_watch()
  if not last_run then
    vim.notify("Run a test first (tn or tf)", vim.log.levels.INFO)
    return false
  end

  watch_enabled = true
  local group = vim.api.nvim_create_augroup(watch_group, { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*",
    callback = function(args)
      if not watch_enabled or not last_run then
        return
      end
      local ft = vim.bo[args.buf].filetype
      if not WATCH_FILETYPES[ft] then
        return
      end
      last_run()
    end,
  })
  return true
end

function M.setup()
  ensure_neotest()
end

function M.watch_enabled()
  return watch_enabled
end

function M.toggle_watch()
  if watch_enabled then
    disable_watch()
    vim.notify("Test watch OFF", vim.log.levels.INFO)
    return false
  end

  if enable_watch() then
    vim.notify("Test watch ON (save buffer to re-run last test)", vim.log.levels.INFO)
    return true
  end
  return false
end

function M.run_nearest()
  last_run = M.run_nearest
  local ft = vim.bo.filetype
  if ft == "java" then
    require("java").run_test_method(false)
  elseif ft == "apex" then
    vim.cmd("SalesforceExecuteCurrentMethod")
  else
    ensure_neotest()
    require("neotest").run.run()
  end
end

function M.run_file()
  last_run = M.run_file
  local ft = vim.bo.filetype
  if ft == "java" then
    require("java").run_test_class()
  elseif ft == "apex" then
    vim.cmd("SalesforceExecuteCurrentClass")
  else
    ensure_neotest()
    require("neotest").run.run(vim.fn.expand("%"))
  end
end

function M.run_debug()
  last_run = M.run_debug
  local ft = vim.bo.filetype
  if ft == "java" then
    require("java").run_test_method(true)
  elseif ft == "apex" then
    vim.notify("Apex test debug not supported", vim.log.levels.WARN)
  else
    ensure_neotest()
    require("neotest").run.run({ strategy = "dap" })
  end
end

function M.run_last()
  if last_run then
    return last_run()
  end
  if vim.bo.filetype == "java" or vim.bo.filetype == "apex" then
    vim.notify("No test run yet this session", vim.log.levels.INFO)
    return
  end
  ensure_neotest()
  require("neotest").run.run_last()
end

return M
