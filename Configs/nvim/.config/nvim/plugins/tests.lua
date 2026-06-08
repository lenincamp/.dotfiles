-- Universal test runner: auto-detects project type and runs the right tool.
-- Java → Maven (mvn test)
-- JS/TS → vitest or jest (detected from package.json)
-- Apex → sf apex run test (via salesforce.nvim or sf CLI directly)
--
-- <leader>t* keymaps — ALL test commands in one group:
--   <leader>tn  nearest test (cursor) — auto-detect
--   <leader>tf  file tests           — auto-detect
--   <leader>tl  run last             — auto-detect
--   <leader>tw  watch mode (JS only)
--   <leader>tt* Java/Maven sub-group (defined in java.lua)
--   <leader>ta  Apex: run test method (defined in salesforce.lua when loaded)
--   <leader>tA  Apex: run test class  (defined in salesforce.lua when loaded)

local map = vim.keymap.set

-- ── Project type detection ────────────────────────────────────────────────────

local function has_file(names)
  for _, name in ipairs(names) do
    if vim.fn.findfile(name, vim.fn.getcwd() .. ";") ~= "" then return true end
  end
  return false
end

local function project_type()
  if has_file({ "sfdx-project.json" })                             then return "apex"  end
  if has_file({ "pom.xml", "build.gradle", "build.gradle.kts" })  then return "java"  end
  if has_file({ "vitest.config.ts", "vitest.config.js",
                "vitest.config.mts", "vitest.workspace.ts" })      then return "vitest" end
  if has_file({ "jest.config.ts", "jest.config.js",
                "jest.config.cjs", "jest.config.mjs" })            then return "jest"  end
  -- fallback: check package.json scripts
  local pkg = vim.fn.findfile("package.json", vim.fn.getcwd() .. ";")
  if pkg ~= "" then
    local ok, content = pcall(vim.fn.readfile, pkg)
    if ok then
      local text = table.concat(content)
      if text:find('"vitest"') then return "vitest" end
      if text:find('"jest"')   then return "jest"   end
    end
  end
  return "unknown"
end

-- ── JS test runner helper ─────────────────────────────────────────────────────

local last_js_cmd = nil

local function run_js(args)
  local pt     = project_type()
  local runner = (pt == "vitest") and "npx vitest" or "npx jest"
  local cmd    = runner .. " " .. args
  last_js_cmd  = cmd
  -- Open a terminal split at the bottom
  vim.cmd("botright 15split | terminal " .. cmd)
  vim.cmd("norm G")
end

-- ── Nearest test (cursor position) ───────────────────────────────────────────

local function run_nearest()
  local pt = project_type()
  if pt == "java" then
    -- Delegate to java.lua maven runner
    local ok, java = pcall(require, "java")
    if ok then java.run_test_method(false) end

  elseif pt == "apex" then
    vim.cmd("SalesforceExecuteCurrentMethod")

  elseif pt == "vitest" or pt == "jest" then
    -- Get test name from treesitter or word under cursor
    local word = vim.fn.expand("<cword>")
    run_js('--reporter verbose -t ' .. vim.fn.shellescape(word))

  else
    vim.notify("No test runner detected for this project", vim.log.levels.WARN)
  end
end

-- ── File tests ────────────────────────────────────────────────────────────────

local function run_file()
  local pt   = project_type()
  local file = vim.fn.expand("%:p")

  if pt == "java" then
    local ok, java = pcall(require, "java")
    if ok then java.run_test_class() end

  elseif pt == "apex" then
    vim.cmd("SalesforceExecuteCurrentClass")

  elseif pt == "vitest" or pt == "jest" then
    run_js("--reporter verbose " .. vim.fn.shellescape(file))

  else
    vim.notify("No test runner detected for this project", vim.log.levels.WARN)
  end
end

-- ── Watch mode (JS only) ──────────────────────────────────────────────────────

local function watch_mode()
  local pt = project_type()
  if pt == "vitest" then
    run_js("--watch")
  elseif pt == "jest" then
    run_js("--watch")
  else
    vim.notify("Watch mode only available for vitest/jest projects", vim.log.levels.INFO)
  end
end

-- ── Run last ─────────────────────────────────────────────────────────────────

local function run_last()
  if last_js_cmd then
    vim.cmd("botright 15split | terminal " .. last_js_cmd)
    vim.cmd("norm G")
  else
    vim.notify("No test run yet this session", vim.log.levels.INFO)
  end
end

-- ── Keymaps ───────────────────────────────────────────────────────────────────

map("n", "<leader>tn", run_nearest, { desc = "Test: nearest (auto)" })
map("n", "<leader>tf", run_file,    { desc = "Test: file (auto)" })
map("n", "<leader>tw", watch_mode,  { desc = "Test: watch (JS)" })
map("n", "<leader>tl", run_last,    { desc = "Test: run last" })
