local M = {}

local profiles = require("modules.autocmds.large_file_profiles")
local large_file_options = require("modules.autocmds.large_file_options")

local function setup_json_filetype()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "json", "jsonc" },
    group = vim.api.nvim_create_augroup("json_large_file", { clear = true }),
    callback = function(ev)
      vim.wo.spell = false
      vim.wo.conceallevel = 0
      vim.bo[ev.buf].tabstop = 2
      vim.bo[ev.buf].shiftwidth = 2
      vim.bo[ev.buf].softtabstop = 2
      vim.b[ev.buf].autoformat = false

      profiles.apply_json_large(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("json_large_file_restore", { clear = true }),
    callback = function(args)
      profiles.clear_override(args.buf, "json_large_global_override_key")
    end,
  })
end

local function setup_huge_text_profile()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("huge_text_profile_apply", { clear = true }),
    callback = function(args)
      if profiles.is_huge_text(args.buf) then
        profiles.apply_huge_text(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("huge_text_profile_restore", { clear = true }),
    callback = function(args)
      if not vim.b[args.buf].huge_text_profile_active then return end

      profiles.clear_override(args.buf, "huge_text_global_override_key")
      profiles.set_number_options(args.buf, true, true)
      vim.b[args.buf].huge_text_profile_active = false
    end,
  })
end

local function setup_huge_code_profile()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("huge_code_profile_apply", { clear = true }),
    callback = function(args)
      if profiles.is_huge_code(args.buf) then
        profiles.apply_huge_code(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("huge_code_profile_restore", { clear = true }),
    callback = function(args)
      if not vim.b[args.buf].huge_code_profile_active then return end

      profiles.clear_override(args.buf, "huge_code_global_override_key")
      profiles.set_number_options(args.buf, true, true)
      vim.b[args.buf].huge_code_profile_active = false
    end,
  })
end

local function setup_json_diff_profile()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("json_diff_optimize", { clear = true }),
    callback = function()
      if vim.bo.filetype ~= "json" or not vim.wo.diff then
        return
      end

      if vim.fn.getfsize(vim.fn.expand("%")) <= profiles.HUGE_FILE_THRESHOLD then
        return
      end

      profiles.apply_json_diff(vim.api.nvim_get_current_buf())
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("json_diff_optimize_restore", { clear = true }),
    callback = function(args)
      profiles.clear_override(args.buf, "json_diff_global_override_key")
    end,
  })
end

local function setup_json_commands()
  vim.api.nvim_create_user_command("JsonOptimizeOn", function()
    profiles.json_manual_on()
  end, { desc = "Disable highlighting/LSP for large JSON" })

  vim.api.nvim_create_user_command("JsonOptimizeOff", function()
    profiles.json_manual_off()
  end, { desc = "Re-enable highlighting/LSP for JSON" })
end

local function setup_insert_redraw_restore()
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = vim.api.nvim_create_augroup("insert_responsive_redraw", { clear = true }),
    callback = function()
      vim.o.lazyredraw = false
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = vim.api.nvim_create_augroup("insert_responsive_redraw_restore", { clear = true }),
    callback = function()
      large_file_options.recompute()
    end,
  })
end

function M.setup()
  setup_json_filetype()
  setup_huge_text_profile()
  setup_huge_code_profile()
  setup_json_diff_profile()
  setup_json_commands()
  setup_insert_redraw_restore()
end

return M