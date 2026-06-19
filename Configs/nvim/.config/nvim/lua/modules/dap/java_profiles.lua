local M = {}

local function buffer_path(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name ~= "" then
      return name
    end
  end
  return nil
end

local function project_root(bufnr)
  local start = buffer_path(bufnr) or vim.fn.getcwd()
  return vim.fs.root(start, { "mvnw", "gradlew", "pom.xml", "build.gradle", ".git" }) or vim.fn.getcwd()
end

local function java_source_paths(bufnr)
  local root = project_root(bufnr)
  local paths = {}
  for _, path in ipairs({
    root .. "/src/main/java",
    root .. "/src/test/java",
  }) do
    if vim.fn.isdirectory(path) == 1 then
      table.insert(paths, path)
    end
  end
  return paths
end

local function java_step_filters()
  return {
    skipClasses = {},
    skipSynthetics = false,
    skipConstructors = false,
    skipStaticInitializers = false,
  }
end

local function java_executable()
  local java = vim.fn.exepath("java")
  return java ~= "" and java or "java"
end

local function java_attach_config(config)
  config.mainClass = ""
  config.modulePaths = {}
  config.classPaths = {}
  config.javaExec = java_executable()
  return config
end

function M.java_configurations(helpers, bufnr)
  local project_name = helpers.java_project_name and helpers.java_project_name(buffer_path(bufnr)) or nil
  return {
    java_attach_config({
      type = "java",
      request = "attach",
      name = "Debug (Attach) — Remote 51922",
      hostName = "127.0.0.1",
      port = 51922,
      projectName = project_name,
      sourcePaths = java_source_paths(bufnr),
      stepFilters = java_step_filters(),
    }),
    {
      type = "java",
      name = "Current File",
      request = "launch",
      mainClass = "${file}",
      projectName = project_name,
      shortenCommandLine = "argfile",
    },
    java_attach_config({
      type = "java",
      request = "attach",
      name = "Remote Attach 5005",
      hostName = "localhost",
      port = 5005,
      projectName = project_name,
      sourcePaths = java_source_paths(bufnr),
      stepFilters = java_step_filters(),
    }),
    java_attach_config({
      type = "java",
      name = "Debug Maven Tests",
      request = "attach",
      hostName = "127.0.0.1",
      port = 5005,
      projectName = project_name,
      sourcePaths = java_source_paths(bufnr),
      stepFilters = java_step_filters(),
    }),
  }
end

return M
