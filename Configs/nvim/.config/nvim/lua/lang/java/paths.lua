local M = {}

local path_core = require("modules.core.path")

M.home = os.getenv("HOME") or ""
M.brew_base = "/opt/homebrew/Cellar"
M.default_java17_home = M.home .. "/Library/Java/JavaVirtualMachines/azul-17.0.11/Contents/Home"

function M.java17_home()
  return vim.env.PURE_JAVA17_HOME or M.default_java17_home
end

function M.java17_env_prefix()
  return "JAVA_HOME=" .. M.java17_home() .. " "
end

function M.resolve_mason_base()
  local own = vim.fn.stdpath("data") .. "/mason/packages/"
  local main = M.home .. "/.local/share/nvim/mason/packages/"
  return vim.fn.isdirectory(own .. "java-debug-adapter") == 1 and own or main
end

function M.normalize_root(root)
  return path_core.normalize(root)
end

function M.workspace_for_root(root)
  root = M.normalize_root(root)
  local project_name = vim.fn.fnamemodify(root, ":t")
  local workspace_id = project_name
  if root ~= "" then
    workspace_id = workspace_id .. "-" .. vim.fn.sha256(root):sub(1, 12)
  end

  local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. workspace_id
  vim.fn.mkdir(workspace_dir, "p")

  return workspace_dir, project_name, root
end

function M.lombok_jar()
  local jar = M.home .. "/.local/share/nvim/mason/packages/jdtls/lombok.jar"
  if vim.fn.filereadable(jar) == 1 then
    return jar
  end

  local candidates = vim.fn.glob(M.home .. "/.m2/repository/org/projectlombok/lombok/*/lombok-*.jar", false, true)
  return (#candidates > 0) and candidates[#candidates] or ""
end

function M.style_file()
  return vim.fn.stdpath("config") .. "/lua/lang/java/SofiProjectsStyle.xml"
end

function M.runtimes()
  return {
    {
      name = "JavaSE-1.8",
      path = "/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home",
    },
    {
      name = "JavaSE-11",
      path = M.brew_base .. "/openjdk@11/11.0.30/libexec/openjdk.jdk/Contents/Home",
    },
    {
      name = "JavaSE-17",
      path = "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home",
    },
    {
      name = "JavaSE-21",
      path = M.brew_base .. "/openjdk@21/21.0.10/libexec/openjdk.jdk/Contents/Home",
      default = true,
    },
  }
end

return M
