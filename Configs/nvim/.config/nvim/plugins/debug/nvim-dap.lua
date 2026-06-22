-- nvim-dap: debug adapter configurations (Java, Kotlin, JS/TS/Node).
-- UI is handled by nvim-dap-view (see plugins/nvim-dap-view.lua).
--
-- How <leader>dc works (universal):
--   • No active session → shows a picker of configs for the current filetype
--   • Active session    → continues execution
-- So <leader>dc IS already universal — it auto-shows Java/Kotlin/JS configs
-- depending on which file is open. No wrapper needed.

local ok_dap, dap = pcall(require, "dap")
if not ok_dap then return end

local controls = require("dap-controls")
controls.setup({ thread_sync = false })  -- thread_sync applied in nvim-dap-view.lua

-- ── DAP keymaps (<leader>d) ─────────────────────────────────────────────────

local helpers = require("dap-controls.helpers")
local keymaps = require("dap-controls.keymaps")

-- Use wrappers so patches applied later (e.g. thread-sync in nvim-dap-view)
-- take effect; direct refs like dap.continue capture a stale function.
keymaps.apply(dap, helpers)

dap.listeners.before.attach["nvim-pure-dap-view"] = function()
  helpers.toggle_dap_view("open")
end

dap.listeners.before.launch["nvim-pure-dap-view"] = function()
  helpers.toggle_dap_view("open")
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dap-view",
  callback = function(args)
    vim.keymap.set("n", "<leader>dW", "<cmd>DapViewWatch<cr>", {
      buffer = args.buf,
      silent = true,
      desc = "Debug: Add watch from dap-view",
    })

    vim.keymap.set("x", "<leader>dW", function()
      local bufnr = vim.api.nvim_get_current_buf()
      local srow, scol = unpack(vim.api.nvim_buf_get_mark(bufnr, "<"))
      local erow, ecol = unpack(vim.api.nvim_buf_get_mark(bufnr, ">"))

      if srow == 0 or erow == 0 then return end
      if srow > erow or (srow == erow and scol > ecol) then
        srow, erow = erow, srow
        scol, ecol = ecol, scol
      end

      local chunks = vim.api.nvim_buf_get_text(bufnr, srow - 1, scol, erow - 1, ecol + 1, {})
      local expr = table.concat(chunks, "\n")

      if not expr or vim.trim(expr) == "" then
        return
      end

      expr = vim.trim(expr):gsub("%s+", " ")

      local ok_dv, dv = pcall(require, "dap-view")
      if not ok_dv then
        vim.notify("dap-view is not available", vim.log.levels.WARN)
        return
      end

      dv.add_expr(expr, true)
    end, {
      buffer = args.buf,
      silent = true,
      desc = "Debug: Add watch from dap-view selection",
    })
  end,
})

local configured = {
  java = false,
  kotlin = false,
  js = false,
}

local js_filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }
local js_filetypes_set = {}
for _, ft in ipairs(js_filetypes) do
  js_filetypes_set[ft] = true
end

local function real_java_file(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  if vim.bo[bufnr].filetype ~= "java" or vim.bo[bufnr].buftype ~= "" then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.startswith(path, "jdt://") then
    return nil
  end

  return path
end

local function has_jdtls_for_buffer(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })) do
    if client.name == "jdtls" then
      return true
    end
  end
  return false
end

local function setup_java_adapter(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not real_java_file(bufnr) then
    return
  end
  if not has_jdtls_for_buffer(bufnr) then
    return
  end

  local ok_jdtls_dap, jdtls_dap = pcall(require, "jdtls.dap")
  if not ok_jdtls_dap then
    return
  end
  jdtls_dap.setup_dap({ hotcodereplace = "auto" })
end

local function ensure_java_config(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if configured.java then
    setup_java_adapter(bufnr)
    return
  end

  local ok_jdtls, jdtls_nvim = pcall(require, "jdtls-nvim")
  if ok_jdtls then
    dap.configurations.java = jdtls_nvim.dap_configurations(bufnr)
  end

  configured.java = true
  setup_java_adapter(bufnr)
end

local function ensure_kotlin_config()
  if configured.kotlin then
    return
  end

  if not dap.adapters.kotlin and vim.fn.executable("kotlin-debug-adapter") == 1 then
    dap.adapters.kotlin = {
      type    = "executable",
      command = "kotlin-debug-adapter",
      options = { auto_continue_if_many_stopped = false },
    }
  end

  dap.configurations.kotlin = {
    {
      type    = "kotlin",
      request = "launch",
      name    = "This file",
      -- Derive fully-qualified class name from file path under src/main/kotlin/
      mainClass = function()
        local root  = vim.fs.find("src", { path = vim.uv.cwd(), upward = true, stop = vim.env.HOME })[1] or ""
        local fname = vim.api.nvim_buf_get_name(0)
        return fname
          :gsub(root, "")
          :gsub("main/kotlin/", "")
          :gsub("%.kt$", "Kt")
          :gsub("/", ".")
          :sub(2)
      end,
      projectRoot      = "${workspaceFolder}",
      jsonLogFile      = "",
      enableJsonLogging = false,
    },
    {
      type        = "kotlin",
      request     = "attach",
      name        = "Attach to debugging session",
      port        = 5005,
      args        = {},
      projectRoot = vim.fn.getcwd,
      hostName    = "localhost",
      timeout     = 2000,
    },
  }

  configured.kotlin = true
end

local function ensure_js_config()
  if configured.js then
    return
  end

  -- Enabled only when js-debug-adapter is installed via Mason.
  -- Install: :MasonInstall js-debug-adapter  (adds Chrome + Node adapters)
  local js_debug = vim.fn.expand("~/.local/share/nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js")
  if vim.fn.filereadable(js_debug) == 0 then
    return
  end

  for _, ft in ipairs(js_filetypes) do
    dap.configurations[ft] = dap.configurations[ft] or {}
    vim.list_extend(dap.configurations[ft], {
      {
        type    = "pwa-node",
        request = "launch",
        name    = "Launch Node (current file)",
        program = "${file}",
        cwd     = "${workspaceFolder}",
      },
      {
        type      = "pwa-node",
        request   = "attach",
        name      = "Attach to Node process",
        processId = require("dap.utils").pick_process,
        cwd       = "${workspaceFolder}",
      },
      {
        type    = "pwa-chrome",
        request = "launch",
        name    = "Launch Chrome (localhost:3000)",
        url     = "http://localhost:3000",
        webRoot = "${workspaceFolder}",
      },
    })
  end

  dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      args    = { js_debug, "${port}" },
    },
  }
  dap.adapters["pwa-chrome"] = dap.adapters["pwa-node"]
  configured.js = true
end

local function ensure_configs_for_filetype(ft, bufnr)
  if ft == "java" then
    ensure_java_config(bufnr)
    return
  end

  if ft == "kotlin" then
    ensure_kotlin_config()
    return
  end

  if js_filetypes_set[ft] then
    ensure_js_config()
  end
end

ensure_configs_for_filetype(vim.bo.filetype, vim.api.nvim_get_current_buf())

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "java", "kotlin", "javascript", "typescript", "javascriptreact", "typescriptreact" },
  callback = function(args)
    ensure_configs_for_filetype(vim.bo[args.buf].filetype, args.buf)
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client_id = args.data and args.data.client_id
    local client = client_id and vim.lsp.get_client_by_id(client_id) or nil
    if client and client.name == "jdtls" then
      setup_java_adapter(args.buf)
    end
  end,
})

-- ── Persistent breakpoints: setup autocmds + load on startup ─────────────────

local ok_bp, bp = pcall(require, "breakpoints")
if ok_bp then
  bp.setup({
    markers = { "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", "package.json" },
    on_setup = function() require("dap-controls.signs").setup() end,
  })
end
