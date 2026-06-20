local M = {}

local runtime = require("modules.core.runtime")

local BREAKPOINTS_DEFER_MS = 500
local EDITING_STACK_DEFER_MS = 160

local EDITING_STACK_CONFIGS = {
  "treesitter-context",
  "flash",
  "mini-surround",
  "ts-comments",
}

local function load_many_once(load_cfg_once, names)
  for _, name in ipairs(names) do
    load_cfg_once(name)
  end
end

local function setup_gitsigns(load_cfg_once)
  local function maybe_load_gitsigns(bufnr)
    local path = bufnr and vim.api.nvim_buf_get_name(bufnr) or ""
    local start = path ~= "" and vim.fs.dirname(path) or vim.fn.getcwd()

    if vim.fs.find(".git", { upward = true, path = start })[1] then
      load_cfg_once("gitsigns")
    end
  end

  vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "DirChanged" }, {
    group = vim.api.nvim_create_augroup("PureLazyGitsigns", { clear = true }),
    callback = function(args)
      if not package.loaded["gitsigns"] then
        maybe_load_gitsigns(args.buf)
      end
    end,
  })

  if not package.loaded["gitsigns"] then
    maybe_load_gitsigns(vim.api.nvim_get_current_buf())
  end
end

local function setup_breakpoints()
  local pending = false

  local function maybe_load_breakpoints()
    pending = false

    if vim.opt.diff:get() then
      return
    end

    local ok, breakpoints = pcall(require, "modules.dap.breakpoints")
    if not ok or not breakpoints.has_saved_project() then
      return
    end

    if runtime.load_pack("nvim-dap") then
      breakpoints.setup()
    end
  end

  local function schedule_breakpoints_load()
    if pending then
      return
    end

    pending = true
    vim.defer_fn(maybe_load_breakpoints, BREAKPOINTS_DEFER_MS)
  end

  vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
    group = vim.api.nvim_create_augroup("PureLazyBreakpoints", { clear = true }),
    callback = schedule_breakpoints_load,
  })
end

local function setup_editing_stack(load_cfg_once)
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("PureLazyEditingStack", { clear = true }),
    callback = function(args)
      if vim.opt.diff:get() then
        return
      end

      load_cfg_once("nvim-treesitter")

      vim.defer_fn(function()
        if not vim.api.nvim_buf_is_valid(args.buf) then
          return
        end

        load_many_once(load_cfg_once, EDITING_STACK_CONFIGS)
      end, EDITING_STACK_DEFER_MS)
    end,
  })
end

local function setup_insert_stack(load_cfg_once)
  local native_pairs_loaded = false
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = vim.api.nvim_create_augroup("PureLazyInsertStack", { clear = true }),
    callback = function()
      if vim.opt.diff:get() then
        return
      end
      if not native_pairs_loaded then
        native_pairs_loaded = true
        require("modules.editor.pairs").setup()
      end
      load_many_once(load_cfg_once, { "minuet", "blink-cmp" })
    end,
  })
end

local function setup_formatter(_load_cfg_once)
  require("modules.editor.format").refresh_autoformat_autocmd()
end

local function setup_markdown(load_cfg_once)
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("PureLazyMarkdown", { clear = true }),
    pattern = { "markdown", "Avante" },
    callback = function()
      load_cfg_once("render-markdown")
    end,
  })
end

local function setup_salesforce(load_cfg_once)
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("PureLazySalesforce", { clear = true }),
    pattern = { "apex", "visualforce", "html", "javascript" },
    callback = function()
      if vim.opt.diff:get() then
        return
      end
      if vim.fn.findfile("sfdx-project.json", vim.fn.getcwd() .. ";") ~= "" then
        load_cfg_once("salesforce")
      end
    end,
  })
end

function M.setup(load_cfg_once)
  setup_gitsigns(load_cfg_once)
  setup_breakpoints()
  setup_editing_stack(load_cfg_once)
  setup_insert_stack(load_cfg_once)
  setup_formatter(load_cfg_once)
  setup_markdown(load_cfg_once)
  setup_salesforce(load_cfg_once)
end

return M
