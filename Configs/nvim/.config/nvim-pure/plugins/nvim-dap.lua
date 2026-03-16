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

-- ── Sign icons (replace the dim built-in "B") ────────────────────────────────
vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DapBreakpoint",         linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint",            { text = "◉", texthl = "DapLogPoint",            linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DapStopped",             linehl = "DapStoppedLine", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DapBreakpointRejected",  linehl = "", numhl = "" })

-- ── DAP keymaps (<leader>d) ─────────────────────────────────────────────────

local map = vim.keymap.set
local helpers = require("dap_helpers")

-- Use wrappers so patches applied later (e.g. thread-sync in nvim-dap-view)
-- take effect; direct refs like dap.continue capture a stale function.
map("n", "<leader>dc", function() dap.continue() end,  { desc = "Debug: Continue" })
map("n", "<leader>dC", helpers.run_to_cursor,           { desc = "Debug: Run to Cursor" })
map("n", "<leader>di", function() dap.step_into() end,  { desc = "Debug: Step Into" })
map("n", "<leader>dO", function() dap.step_out() end,   { desc = "Debug: Step Out" })
map("n", "<leader>do", function() dap.step_over() end,  { desc = "Debug: Step Over" })
map("n", "<leader>dP", dap.pause,              { desc = "Debug: Pause" })
map("n", "<leader>db", helpers.toggle_breakpoint_and_save, { desc = "Debug: Toggle Breakpoint" })
map("n", "<leader>dB", helpers.conditional_breakpoint_prompt, { desc = "Debug: Conditional Breakpoint" })
map("n", "<leader>dL", helpers.logpoint_prompt, { desc = "Debug: Logpoint" })
map("n", "<leader>dl", dap.run_last,           { desc = "Debug: Run Last" })
map("n", "<leader>dt", dap.terminate,          { desc = "Debug: Terminate" })
map("n", "<leader>dd", dap.disconnect,         { desc = "Debug: Disconnect" })
map("n", "<leader>dr", helpers.open_repl_view, { desc = "Debug: Open REPL View" })
map("x", "<leader>dr", helpers.eval_visual_selection_in_repl, { desc = "Debug: Eval Selection in REPL" })
map("n", "<leader>ds", helpers.show_session,   { desc = "Debug: Session" })
map("n", "<leader>dw", helpers.hover_widget,   { desc = "Debug: Widgets" })
map({ "n", "v" }, "<leader>de", helpers.hover_widget, { desc = "Debug: Eval" })
map("n", "<leader>dE", helpers.eval_expression_prompt, { desc = "Debug: Eval/Set Expression" })
map("n", "<leader>dW", helpers.add_watch_prompt, { desc = "Debug: Add Watch" })
map("x", "<leader>dW", helpers.add_watch_from_visual_selection, { desc = "Debug: Add Watch from Selection" })
map("n", "<leader>dj", dap.down,               { desc = "Debug: Down (stack)" })
map("n", "<leader>dk", dap.up,                 { desc = "Debug: Up (stack)" })
map("n", "<leader>dg", helpers.goto_line_prompt, { desc = "Debug: Go to Line" })
map("n", "<leader>dm", helpers.run_to_method_breakpoint, { desc = "Debug: Method Breakpoint Picker" })
map("n", "<leader>da", helpers.continue_with_args_prompt, { desc = "Debug: Run with Args" })
map("n", "<leader>du", helpers.toggle_dap_view, { desc = "Debug: Toggle DAP View" })

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

-- ── helpers ───────────────────────────────────────────────────────────────────

local function project_root()
  return vim.fs.root(0, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" })
    or vim.fn.getcwd()
end

local function java_source_paths()
  local root = project_root()
  return {
    root .. "/src/main/java",
    root .. "/src/test/java",
  }
end

local function java_step_filters()
  return {
    skipClasses = {},
    skipSynthetics = false,
    skipConstructors = false,
    skipStaticInitializers = false,
  }
end

-- ── Java configurations ───────────────────────────────────────────────────────

dap.configurations.java = {
  {
    type              = "java",
    request           = "attach",
    name              = "Debug (Attach) — Remote 51922",
    hostName          = "127.0.0.1",
    port              = 51922,
    sourcePaths       = java_source_paths(),
    stepFilters       = java_step_filters(),
  },
  {
    type              = "java",
    name              = "Current File",
    request           = "launch",
    mainClass         = "${file}",
    shortenCommandLine = "argfile",
  },
  {
    type     = "java",
    request  = "attach",
    name     = "Remote Attach 5005",
    hostName = "localhost",
    port     = 5005,
    sourcePaths = java_source_paths(),
    stepFilters = java_step_filters(),
  },
  {
    type              = "java",
    name              = "Debug Maven Tests",
    request           = "attach",
    hostName          = "127.0.0.1",
    port              = 5005,
    sourcePaths       = java_source_paths(),
    stepFilters       = java_step_filters(),
  },
}

-- ── Kotlin configurations ─────────────────────────────────────────────────────

if not dap.adapters.kotlin then
  dap.adapters.kotlin = {
    type    = "executable",
    command = "kotlin-debug-adapter",
    options = { auto_continue_if_many_stopped = false },
  }
end

-- ── JavaScript / TypeScript / Node (optional) ─────────────────────────────────
-- Enabled only when js-debug-adapter is installed via Mason.
-- Install: :MasonInstall js-debug-adapter  (adds Chrome + Node adapters)

local js_debug = vim.fn.expand("~/.local/share/nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js")
if vim.fn.filereadable(js_debug) == 1 then
  for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
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
end

-- ── Breakpoint persistence keymaps (<leader>db) ───────────────────────────────

map("n", "<leader>dbs", helpers.breakpoints_save,   { desc = "Breakpoints: Save" })
map("n", "<leader>dbL", helpers.breakpoints_load,   { desc = "Breakpoints: Load" })
map("n", "<leader>dbg", helpers.breakpoints_assign_group, { desc = "Breakpoints: Assign group" })
map("n", "<leader>dbp", helpers.breakpoints_picker, { desc = "Breakpoints: Browse by group" })

-- ── Persistent breakpoints: setup autocmds + load on startup ─────────────────

local ok_bp, bp = pcall(require, "breakpoints")
if ok_bp then
  bp.setup()  -- auto-load is handled inside setup() via vim.schedule
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
