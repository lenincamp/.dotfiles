-- Java utility functions: test execution, character escaping, DAP & editor keymaps.
-- Required by ftplugin/java.lua on_attach; also usable from any Java buffer.

local M = {}

local local_state = {} -- stores original lines for escape toggle

local java_17_home =
  "JAVA_HOME=/Users/lcampoverde/Library/Java/JavaVirtualMachines/azul-17.0.11/Contents/Home "

-- ──────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ──────────────────────────────────────────────────────────────────────────────

local function get_class_name()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_pos = vim.api.nvim_win_get_cursor(0)
  local pattern = "class%s+(%w+)"
  for i = current_pos[1], 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    local name = line:match(pattern)
    if name then return name end
  end
  return "UnknownClass"
end

local function get_method_name()
  return vim.fn.expand("<cword>")
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Public: escape / unescape accented characters ↔ unicode escapes
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
  local base = java_17_home
    .. "mvn test -Dtest=%s#%s -DfailIfNoTests=false -Djacoco.skip=true"
    .. " -Dmaven.javadoc.skip=true -Dmaven.site.skip=true"
    .. " -Dsurefire.useFile=false -DtrimStackTrace=false"
    .. " -Dmaven.source.skip=true -o -B -pl api -am"
  local cmd = is_debug and (base .. " -Dmaven.surefire.debug") or base
  local maven_cmd = string.format(cmd, get_class_name(), get_method_name())
    .. ' | grep -A 10 -B 1 "T E S T S"'
  vim.fn.system("tmux send-keys -t scratch '" .. maven_cmd .. "' C-m")
  vim.notify("executing: " .. maven_cmd, vim.log.levels.INFO)
end

function M.run_test_class()
  local base = java_17_home
    .. "mvn test -Dtest=%s -DfailIfNoTests=false -Djacoco.skip=true"
    .. " -Dmaven.javadoc.skip=true -Dmaven.site.skip=true"
    .. " -Dsurefire.useFile=false -DtrimStackTrace=false"
    .. " -Dmaven.source.skip=true -o -B -pl api -am"
  local maven_cmd = string.format(base, get_class_name())
    .. ' | grep -A 100 "T E S T S" | grep -B 100 "BUILD SUCCESS"'
  vim.fn.system("tmux send-keys -t scratch '" .. maven_cmd .. "' C-m")
  vim.notify("executing Test Class: " .. maven_cmd, vim.log.levels.INFO)
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

  -- JDTLS helpers
  map("n", "<leader>Ju", "<Cmd>JdtUpdateConfig<CR>", "[J]ava [U]pdate Config")

  -- Snacks: decompiled JAR exploration
  map("n", "<leader>Jd", function()
    require("snacks").explorer.open({ cwd = vim.fn.expand("$HOME/.cache/java-decompiled/") })
  end, "Java: Explore decompiled Jars")

  map("n", "<leader>Jg", function()
    require("snacks").picker.grep({ dirs = { vim.fn.expand("$HOME/.cache/java-decompiled/") } })
  end, "Java: Grep decompiled Jars")

  map("n", "<leader>JG", function()
    require("snacks").picker.grep({
      dirs = { vim.fn.getcwd(), vim.fn.expand("$HOME/.cache/java-decompiled/") },
    })
  end, "Java: Grep project + Jars")

  -- DAP keymaps unique to Java buffers (log point, clear breaks)
  -- <leader>dd and <leader>dt are global (nvim-dap.lua) — not duplicated here
  if vim.api.nvim_buf_is_valid(bufnr) then
    map("n", "<leader>dbl", function()
      require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
      vim.schedule(function()
        local bp = require("breakpoints")
        bp.mark_dirty()
        bp.save()
      end)
    end, "DAP: Set log point")

    map("n", "<leader>dbr", function()
      require("dap").clear_breakpoints()
      vim.schedule(function()
        local bp = require("breakpoints")
        bp.mark_dirty()
        bp.save()
      end)
    end, "DAP: Clear breakpoints")
  end
end

return M
