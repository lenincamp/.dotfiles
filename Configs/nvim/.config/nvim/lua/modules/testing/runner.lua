local M = {}

local last_js_cmd = nil

local keymap_specs = {
  { mode = "n", lhs = "<leader>tn", action = "run_nearest", desc = "Test: nearest (auto)" },
  { mode = "n", lhs = "<leader>tf", action = "run_file", desc = "Test: file (auto)" },
  { mode = "n", lhs = "<leader>tw", action = "watch_mode", desc = "Test: watch (JS)" },
  { mode = "n", lhs = "<leader>tl", action = "run_last", desc = "Test: run last" },
}

local function has_file(names)
  for _, name in ipairs(names) do
    if vim.fn.findfile(name, vim.fn.getcwd() .. ";") ~= "" then
      return true
    end
  end
  return false
end

function M.project_type()
  if has_file({ "sfdx-project.json" }) then
    return "apex"
  end
  if has_file({ "pom.xml", "build.gradle", "build.gradle.kts" }) then
    return "java"
  end
  if has_file({ "vitest.config.ts", "vitest.config.js", "vitest.config.mts", "vitest.workspace.ts" }) then
    return "vitest"
  end
  if has_file({ "jest.config.ts", "jest.config.js", "jest.config.cjs", "jest.config.mjs" }) then
    return "jest"
  end

  local pkg = vim.fn.findfile("package.json", vim.fn.getcwd() .. ";")
  if pkg ~= "" then
    local ok, content = pcall(vim.fn.readfile, pkg)
    if ok then
      local text = table.concat(content)
      if text:find('"vitest"') then
        return "vitest"
      end
      if text:find('"jest"') then
        return "jest"
      end
    end
  end

  return "unknown"
end

function M.run_js(args)
  local pt = M.project_type()
  local runner = (pt == "vitest") and "npx vitest" or "npx jest"
  local cmd = runner .. " " .. args
  last_js_cmd = cmd
  vim.cmd("botright 15split | terminal " .. cmd)
  vim.cmd("norm G")
end

function M.run_nearest()
  local pt = M.project_type()
  if pt == "java" then
    local ok, java = pcall(require, "java")
    if ok then
      java.run_test_method(false)
    end
  elseif pt == "apex" then
    vim.cmd("SalesforceExecuteCurrentMethod")
  elseif pt == "vitest" or pt == "jest" then
    local word = vim.fn.expand("<cword>")
    M.run_js('--reporter verbose -t ' .. vim.fn.shellescape(word))
  else
    vim.notify("No test runner detected for this project", vim.log.levels.WARN)
  end
end

function M.run_file()
  local pt = M.project_type()
  local file = vim.fn.expand("%:p")

  if pt == "java" then
    local ok, java = pcall(require, "java")
    if ok then
      java.run_test_class()
    end
  elseif pt == "apex" then
    vim.cmd("SalesforceExecuteCurrentClass")
  elseif pt == "vitest" or pt == "jest" then
    M.run_js("--reporter verbose " .. vim.fn.shellescape(file))
  else
    vim.notify("No test runner detected for this project", vim.log.levels.WARN)
  end
end

function M.watch_mode()
  local pt = M.project_type()
  if pt == "vitest" or pt == "jest" then
    M.run_js("--watch")
  else
    vim.notify("Watch mode only available for vitest/jest projects", vim.log.levels.INFO)
  end
end

function M.run_last()
  if last_js_cmd then
    vim.cmd("botright 15split | terminal " .. last_js_cmd)
    vim.cmd("norm G")
  else
    vim.notify("No test run yet this session", vim.log.levels.INFO)
  end
end

function M.setup_keymaps()
  for _, spec in ipairs(keymap_specs) do
    vim.keymap.set(spec.mode, spec.lhs, M[spec.action], { desc = spec.desc })
  end
end

function M.lazy_specs()
  local out = {}
  for _, spec in ipairs(keymap_specs) do
    out[#out + 1] = {
      mode = spec.mode,
      lhs = spec.lhs,
      desc = spec.desc,
    }
  end
  return out
end

return M
