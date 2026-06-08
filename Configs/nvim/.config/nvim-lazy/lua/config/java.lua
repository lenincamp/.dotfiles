local local_state = {} -- Tabla para almacenar el estado original del texto

function _G.escape_characters()
  local start, finish = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local bufnr = vim.fn.bufnr()

  if local_state[bufnr] then
    vim.api.nvim_buf_set_lines(0, start[2] - 1, finish[2], false, local_state[bufnr])
    local_state[bufnr] = nil
  else
    local_state[bufnr] = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)

    local reemplazos = {
      ["ó"] = "\\u00F3",
      ["á"] = "\\u00E1",
      ["é"] = "\\u00E9",
      ["í"] = "\\u00ED",
      ["ú"] = "\\u00FA",
      ["Á"] = "\\u00C1",
      ["É"] = "\\u00C9",
      ["Í"] = "\\u00CD",
      ["Ó"] = "\\u00D3",
      ["Ú"] = "\\u00DA",
      ["ñ"] = "\\u00F1",
      ["Ñ"] = "\\u00D1",
    }

    local lines = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)
    for i, line in ipairs(lines) do
      for char, reemplazo in pairs(reemplazos) do
        line = string.gsub(line, char, reemplazo)
      end
      lines[i] = line
    end

    vim.api.nvim_buf_set_lines(0, start[2] - 1, finish[2], false, lines)
  end
end

local function get_class_name()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_pos = vim.api.nvim_win_get_cursor(0)

  local class_pattern = "class%s+(%w+)"
  for i = current_pos[1], 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    local class_name = line:match(class_pattern)
    if class_name then
      return class_name
    end
  end
  return "UnknownClass"
end

local function get_method_name()
  return vim.fn.expand("<cword>")
end

local java_17_home = "JAVA_HOME=/Users/lcampoverde/Library/Java/JavaVirtualMachines/azul-17.0.11/Contents/Home "

function _G.run_test_method(isTest)
  local base_command = java_17_home
    .. "mvn test -Dtest=%s#%s -DfailIfNoTests=false -Djacoco.skip=true -Dmaven.javadoc.skip=true -Dmaven.site.skip=true -Dsurefire.useFile=false -DtrimStackTrace=false -Dmaven.source.skip=true -o -B -pl api -am" --commented ,backoffice
  local command = isTest and base_command .. " -Dmaven.surefire.debug" or base_command
  local maven_test_command = string.format(command, get_class_name(), get_method_name())
    .. '| grep -A 10 -B 1 "T E S T S"'
  vim.fn.system("tmux send-keys -t scratch '" .. maven_test_command .. "' C-m")

  -- Execute maven command in tmux popup
  -- local full_command = string.format("tmux display-popup -w 80%% -h 60%% '%s'", maven_test_command)
  -- vim.fn.system(full_command)

  -- Open terminal and execute maven command
  -- vim.cmd("split")
  -- vim.cmd("terminal")
  -- vim.fn.chansend(vim.b.terminal_job_id, maven_test_command .. "\n")

  -- Show message
  vim.notify("executing: " .. maven_test_command, vim.log.levels.INFO)
end

function _G.run_test_class()
  local base_command = java_17_home
    .. "mvn test -Dtest=%s -DfailIfNoTests=false -Djacoco.skip=true -Dmaven.javadoc.skip=true -Dmaven.site.skip=true  -Dsurefire.useFile=false -DtrimStackTrace=false -Dmaven.source.skip=true -o -B -pl api -am" --,backoffice is commented when in need
  local maven_test_command = string.format(base_command, get_class_name())
    .. '| grep -A 100 "T E S T S" | grep -B 100 "BUILD SUCCESS"'
  -- Execute command in tmux popup (key π)
  vim.fn.system("tmux send-keys -t scratch '" .. maven_test_command .. "' C-m")
  vim.notify("executing Test Class: " .. maven_test_command, vim.log.levels.INFO)
end

function _G.java_keymaps(bufnr)
  vim.api.nvim_set_keymap(
    "v",
    "<leader>Jec",
    ":lua require('config.java').escape_characters()<CR>",
    { noremap = true, silent = true }
  )
  vim.keymap.set(
    "n",
    "<leader>ttm",
    "<Cmd>:lua require('config.java').run_test_method(false)<CR>",
    { noremap = true, silent = true, desc = "[M]aven [R]un Test Method" }
  )
  vim.keymap.set(
    "n",
    "<leader>ttc",
    "<Cmd>:lua require('config.java').run_test_class()<CR>",
    { noremap = true, silent = true, desc = "[M]aven Run Test [C]lass" }
  )
  vim.keymap.set(
    "n",
    "<leader>tdm",
    "<Cmd>:lua require('config.java').run_test_method(true)<CR>",
    { noremap = true, silent = true, desc = "[M]aven [D]ebug Test Method" }
  )

  --vsc test
  vim.keymap.set("n", "<leader>Ju", "<Cmd>JdtUpdateConfig<CR>", { desc = "[J]ava [U]pdate Config" })

  -- open deccompiled java files on snacks explorer
  vim.keymap.set("n", "<leader>Jd", function()
    require("snacks").explorer.open({
      cwd = vim.fn.expand("$HOME/.cache/java-decompiled/"),
    })
  end, { desc = "Java: Explore decompiled Jars" })

  -- find explicit text on decompiled java files with snacks grep
  vim.keymap.set("n", "<leader>Jg", function()
    require("snacks").picker.grep({
      dirs = {
        vim.fn.expand("$HOME/.cache/java-decompiled/"),
      },
    })
  end, { desc = "Java: Grep decompiled Jars" })

  -- find text in the project and decompiled java files with snacks grep
  vim.keymap.set("n", "<leader>JG", function()
    require("snacks").picker.grep({
      dirs = {
        vim.fn.getcwd(),
        vim.fn.expand("$HOME/.cache/java-decompiled/"),
      },
    })
  end, { desc = "Java: Grep project + Jars" })

  if vim.api.nvim_buf_is_valid(bufnr) then
    -- nvim-dap
    vim.keymap.set("n", "<leader>dbl", function()
      require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
    end, { desc = "Set log point" })
    vim.keymap.set("n", "<leader>dbr", function()
      require("dap").clear_breakpoints()
    end, { desc = "Clear breakpoints" })
    vim.keymap.set("n", "<leader>dd", function()
      require("dap").disconnect()
    end, { desc = "Disconnect" })
    vim.keymap.set("n", "<leader>dt", function()
      require("dap").terminate()
    end, { desc = "Terminate" })
  end
end
return _G
