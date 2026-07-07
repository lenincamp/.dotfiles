-- Java workflow: Maven tests, scaffolding, decompile navigation, escape chars.
-- Tests: <leader>tn/tf/td/tl → run_test_method / run_test_class (config.test)

local M = {}

local shell = require("modules.util.shell")

-- ──────────────────────────────────────────────────────────────────────────────
-- Test runners (Maven → tmux scratch)
-- ──────────────────────────────────────────────────────────────────────────────

local function ts_parent(match)
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok then return nil end
  while node do
    if match(node:type()) then return node end
    node = node:parent()
  end
end

local function ts_name(node)
  local name = node and node:child_by_field_name("name")
  return name and vim.treesitter.get_node_text(name, 0) or nil
end

local function get_class_name_fallback()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_pos = vim.api.nvim_win_get_cursor(0)
  for i = current_pos[1], 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    local name = line:match("%f[%w]class%s+(%w+)")
        or line:match("%f[%w]record%s+(%w+)")
        or line:match("%f[%w]interface%s+(%w+)")
        or line:match("%f[%w]enum%s+(%w+)")
    if name then return name end
  end
  return nil
end

local function get_method_name_fallback()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_pos = vim.api.nvim_win_get_cursor(0)
  for i = current_pos[1], 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    local name = line:match("[%w_<>,%[%]%s]+%s+(%w+)%s*%([^;]*%)%s*[%{%w]*")
    if name then return name end
  end
  return nil
end

local function get_class_name()
  return ts_name(ts_parent(function(t)
    return t == "class_declaration" or t == "record_declaration"
        or t == "interface_declaration" or t == "enum_declaration"
  end)) or get_class_name_fallback()
end

local function get_method_name()
  return ts_name(ts_parent(function(t) return t == "method_declaration" end))
      or get_method_name_fallback()
end

function M.run_test_method(is_debug)
  local class_name = get_class_name()
  local method_name = get_method_name()
  if not class_name or not method_name then
    vim.notify("No Java test method found under cursor", vim.log.levels.WARN)
    return
  end

  local command = require("jdtls-nvim").maven().test_method(class_name, method_name, {
    bufnr = 0,
    debug = true,
    debug_suspend = is_debug == true,
  })
  shell.tmux_send_keys("scratch", command)
  vim.notify("executing: " .. command, vim.log.levels.INFO)
end

function M.run_test_class()
  local class_name = get_class_name()
  if not class_name then
    vim.notify("No Java test class found under cursor", vim.log.levels.WARN)
    return
  end

  local command = require("jdtls-nvim").maven().test_class(class_name, {
    bufnr = 0,
    debug = true,
    debug_suspend = false,
  })
  shell.tmux_send_keys("scratch", command)
  vim.notify("executing Test Class: " .. command, vim.log.levels.INFO)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Escape accented characters (toggle)
-- ──────────────────────────────────────────────────────────────────────────────

local escape_state = {}

function M.escape_characters()
  local start  = vim.fn.getpos("'<")
  local finish = vim.fn.getpos("'>")
  local bufnr  = vim.fn.bufnr()

  if escape_state[bufnr] then
    vim.api.nvim_buf_set_lines(0, start[2] - 1, finish[2], false, escape_state[bufnr])
    escape_state[bufnr] = nil
  else
    escape_state[bufnr] = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)

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
-- Decompiled buffer navigation
-- ──────────────────────────────────────────────────────────────────────────────

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

  vim.ui.select(items, {
    prompt = "Decompiled JDTLS Buffers",
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
-- Java file scaffolding (class, interface, enum)
-- ──────────────────────────────────────────────────────────────────────────────

local function current_package()
  if vim.bo.filetype == "java" then
    local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
    for _, line in ipairs(lines) do
      local pkg = line:match("^%s*package%s+([%w%.]+)%s*;")
      if pkg then return pkg end
    end
  end

  local current_file = vim.fn.expand("%:p")
  local package_path = current_file:match("src/main/java/(.+)/[^/]+%.java$")
    or current_file:match("src/test/java/(.+)/[^/]+%.java$")
    or ""

  return package_path:gsub("/", ".")
end

local function current_source_root()
  local current_file = vim.fn.expand("%:p")
  return current_file:match("^(.*src/main/java/)")
    or current_file:match("^(.*src/test/java/)")
    or (vim.fs.root(0, { "pom.xml", "gradlew", "build.gradle" }) or vim.fn.getcwd()) .. "/src/main/java/"
end

local function split_last(value)
  local dot = value:match(".*()%.")
  if dot then
    return value:sub(1, dot - 1), value:sub(dot + 1)
  end
  return "", value
end

local function parse_input(input, base_package)
  if input:sub(1, 1) == "." then
    local rest = input:sub(2)
    local sub_package, name = split_last(rest)
    if name == "" then
      name, sub_package = sub_package, ""
    end

    local package_name = (base_package ~= "" and sub_package ~= "") and (base_package .. "." .. sub_package)
      or (base_package ~= "" and base_package)
      or sub_package
    return package_name, name
  end

  if input:find("%.") then
    return split_last(input)
  end

  return base_package, input
end

local function package_header(package_name)
  return package_name ~= "" and { "package " .. package_name .. ";", "" } or {}
end

local function create_java_file(type_label, template)
  local base_package = current_package()
  local source_root = current_source_root()
  local hint = base_package ~= "" and ("[" .. base_package .. "] ") or "[no package] "

  vim.ui.input({
    prompt = type_label .. " " .. hint .. "(Name, .sub.Name, pkg.Name): ",
    scope = "project",
  }, function(input)
    if not input or input == "" then return end

    local package_name, name = parse_input(input, base_package)
    if not name:match("^[A-Z][%w_]*$") then
      vim.notify("Name must be PascalCase: " .. name, vim.log.levels.ERROR)
      return
    end

    local target_dir = source_root .. package_name:gsub("%.", "/")
    vim.fn.mkdir(target_dir, "p")

    local filepath = target_dir .. "/" .. name .. ".java"
    if vim.fn.filereadable(filepath) == 1 then
      vim.notify(type_label .. " already exists: " .. filepath, vim.log.levels.WARN)
      return
    end

    vim.fn.writefile(template(package_name, name), filepath)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))

    local location = package_name ~= "" and package_name or "(default package)"
    vim.notify("Created: " .. name .. ".java  [" .. location .. "]", vim.log.levels.INFO)
  end)
end

function M.create_class()
  create_java_file("class", function(package_name, name)
    local lines = package_header(package_name)
    vim.list_extend(lines, { "public class " .. name .. " {", "", "}" })
    return lines
  end)
end

function M.create_interface()
  create_java_file("interface", function(package_name, name)
    local lines = package_header(package_name)
    vim.list_extend(lines, { "public interface " .. name .. " {", "", "}" })
    return lines
  end)
end

function M.create_enum()
  create_java_file("enum", function(package_name, name)
    local lines = package_header(package_name)
    vim.list_extend(lines, { "public enum " .. name .. " {", "", "}" })
    return lines
  end)
end

function M.run_spring_project()
  local root = vim.fs.root(0, { "pom.xml", "build.gradle", "build.gradle.kts" }) or vim.fn.getcwd()
  local command

  if vim.fn.filereadable(root .. "/pom.xml") == 1 then
    command = "cd " .. vim.fn.shellescape(root) .. " && mvn spring-boot:run"
  else
    command = "cd " .. vim.fn.shellescape(root) .. " && ./gradlew bootRun"
  end

  shell.open_terminal(command)
  vim.cmd("startinsert")
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Keymaps: registers all Java buffer-local keymaps (called from on_attach)
-- ──────────────────────────────────────────────────────────────────────────────

function M.java_keymaps(bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  -- Escape accented chars (visual)
  map("v", "<leader>Jec", ":<C-u>lua require('java').escape_characters()<CR>",
    "[J]ava [E]scape [C]haracters")

  -- Tests: <leader>tn/tf/td/tl (config.test)

  -- Decompiled / external class navigation
  map("n", "<leader>Jdd", vim.lsp.buf.definition,
    "[J]ava [D]ecompile/go to definition")
  map("n", "<leader>Jdp", function() require("lsp-nav").peek("textDocument/definition") end,
    "[J]ava [D]ecompiled peek definition")
  map("n", "<leader>Jdb", M.select_decompiled_buffer,
    "[J]ava [D]ecompiled buffers")
  map("n", "<leader>Jdy", M.copy_decompiled_uri,
    "[J]ava [D]ecompiled copy URI")

  -- Scaffolding
  map("n", "<leader>Jtc", M.create_class, "Spring: Create class")
  map("n", "<leader>Jtn", M.create_interface, "Spring: Create interface")
  map("n", "<leader>Jte", M.create_enum, "Spring: Create enum")
  map("n", "<leader>Jtr", M.run_spring_project, "Spring: Run project")
end

return M
