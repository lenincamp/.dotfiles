-- Java utility functions: test execution, character escaping, DAP & editor keymaps.
-- Required by ftplugin/java.lua on_attach; also usable from any Java buffer.

local M = {}

local local_state = {} -- stores original lines for escape toggle
local java_test = require("lang.java.test")

-- ──────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ──────────────────────────────────────────────────────────────────────────────

function M.escape_characters()
  local start  = vim.fn.getpos("'<")
  local finish = vim.fn.getpos("'>")
  local bufnr  = vim.fn.bufnr()

  if local_state[bufnr] then
    -- Restore original text (toggle back)
    vim.api.nvim_buf_set_lines(0, start[2] - 1, finish[2], false, local_state[bufnr])
    local_state[bufnr] = nil
  else
    -- Save original and apply escapes
    local_state[bufnr] = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)

    local replacements = {
      ["ó"] = "\\u00F3", ["á"] = "\\u00E1", ["é"] = "\\u00E9",
      ["í"] = "\\u00ED", ["ú"] = "\\u00FA", ["Á"] = "\\u00C1",
      ["É"] = "\\u00C9", ["Í"] = "\\u00CD", ["Ó"] = "\\u00D3",
      ["Ú"] = "\\u00DA", ["ñ"] = "\\u00F1", ["Ñ"] = "\\u00D1",
    }

    local lines = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)
    for i, line in ipairs(lines) do
      for char, esc in pairs(replacements) do
        line = string.gsub(line, char, esc)
      end
      lines[i] = line
    end
    vim.api.nvim_buf_set_lines(0, start[2] - 1, finish[2], false, lines)
  end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Public: Maven test runners (send to tmux scratch window)
-- ──────────────────────────────────────────────────────────────────────────────

function M.run_test_method(is_debug)
  java_test.run_method(is_debug)
end

function M.run_test_class()
  java_test.run_class()
end

local function jdt_buffers()
  local items = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name:match("^jdt://") then
        items[#items + 1] = {
          bufnr = bufnr,
          name = name,
          label = name:gsub("^jdt://contents/", ""),
        }
      end
    end
  end
  return items
end

function M.select_decompiled_buffer()
  local items = jdt_buffers()
  if #items == 0 then
    vim.notify("No decompiled JDTLS buffers open", vim.log.levels.INFO)
    return
  end

  require("modules.editor.picker").select_items(items, {
    prompt = "Decompiled JDTLS Buffers",
    search_threshold = 0,
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      vim.cmd("buffer " .. item.bufnr)
    end
  end)
end

function M.copy_decompiled_uri()
  local name = vim.api.nvim_buf_get_name(0)
  if not name:match("^jdt://") then
    vim.notify("Current buffer is not a JDTLS decompiled source", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", name)
  vim.notify("Copied JDTLS URI", vim.log.levels.INFO)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Public: register all Java buffer-local keymaps (called from on_attach)
-- ──────────────────────────────────────────────────────────────────────────────

function M.java_keymaps(bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  -- Escape accented chars (visual)
  map("v", "<leader>Jec", ":<C-u>lua require('java').escape_characters()<CR>",
    "[J]ava [E]scape [C]haracters")

  -- Maven test runners
  map("n", "<leader>ttm", function() M.run_test_method(false) end,
    "[M]aven [R]un Test [M]ethod")
  map("n", "<leader>ttc", function() M.run_test_class() end,
    "[M]aven Run Test [C]lass")
  map("n", "<leader>tdm", function() M.run_test_method(true) end,
    "[M]aven [D]ebug Test Method")

  -- Decompiled / external class navigation
  map("n", "<leader>Jdd", vim.lsp.buf.definition,
    "[J]ava [D]ecompile/go to definition")
  map("n", "<leader>Jdp", function() require("modules.editor.peek").request("textDocument/definition") end,
    "[J]ava [D]ecompiled peek definition")
  map("n", "<leader>Jdb", M.select_decompiled_buffer,
    "[J]ava [D]ecompiled buffers")
  map("n", "<leader>Jdy", M.copy_decompiled_uri,
    "[J]ava [D]ecompiled copy URI")

  -- DAP mappings are global in plugins/nvim-dap.lua
end

return M
