local M = {}

local shell = require("modules.core.shell")

local function current_package()
  if vim.bo.filetype == "java" then
    local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
    for _, line in ipairs(lines) do
      local pkg = line:match("^%s*package%s+([%w%.]+)%s*;")
      if pkg then
        return pkg
      end
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
    if not input or input == "" then
      return
    end

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

function M.map_keymaps(map)
  map("<leader>Jtc", M.create_class, "Spring: Create class")
  map("<leader>Jtn", M.create_interface, "Spring: Create interface")
  map("<leader>Jte", M.create_enum, "Spring: Create enum")
  map("<leader>Jtr", M.run_spring_project, "Spring: Run project")
end

return M