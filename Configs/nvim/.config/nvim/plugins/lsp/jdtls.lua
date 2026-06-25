-- jdtls.nvim plugin configuration.
-- Delegates JDTLS lifecycle to the plugin; project-specific behavior is resolved by root.

local function patagonia_root(start_path)
  start_path = start_path or vim.loop.cwd()
  local git_root = vim.fs.root(start_path, { ".git" })
  if git_root
      and vim.fn.filereadable(git_root .. "/pom.xml") == 1
      and vim.fn.filereadable(git_root .. "/ci-settings-tech-proyecto.xml") == 1 then
    return vim.fn.resolve(git_root):gsub("/+$", "")
  end
  return nil
end

local function patagonia_overrides(root_dir)
  if not patagonia_root(root_dir) then
    return nil
  end

  return {
    maven_user_settings = root_dir .. "/ci-settings-tech-proyecto.xml",
    maven_lifecycle_mappings = vim.fn.stdpath("config") .. "/lua/lang/java/sofi-patagonia-m2e-lifecycle.xml",
    update_build_configuration = "interactive",
    null_analysis_mode = "automatic",
    style_file = vim.fn.stdpath("config") .. "/lua/lang/java/SofiProjectsStyle.xml",
    format_profile = "Patagonia-Style",
    extra_import_exclusions = {
      "**/frontend/**",
      "**/frontend/apps/**",
      "**/frontend/node_modules/**",
      "**/frontend/**/node_modules/**",
      "**/frontend/**/dist/**",
      "**/frontend/**/build/**",
      "**/frontend/**/coverage/**",
      "**/cybo*/**",
      "**/tools/**",
      "**/docker/**",
      "**/.git/**",
      "**/.idea/**",
      "**/target/**",
      "**/dist/**",
      "**/build/**",
      "**/out/**",
    },
  }
end

require("jdtls-nvim").setup({
  -- jenv supplies JAVA_HOME for JDTLS and java.configuration.runtimes.
  jenv = {
    enabled = true,
    use_java_home = true,
    runtimes = "active",
  },

  -- Patagonia CDP is a Maven reactor: use repo root instead of child module pom.xml.
  root_resolver = function(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    return patagonia_root(path ~= "" and path or vim.loop.cwd())
  end,

  project_overrides = patagonia_overrides,

  -- Lombok auto-detection (Mason → ~/.m2)
  lombok = true,

  -- Keep JDTLS logs light for large Maven workspaces; enable verbose only when debugging the server.
  jdtls_log_protocol = false,
  jdtls_log_level = "WARN",

  -- Feature toggles
  semantic_tokens = false,
  inlay_hints = false,
  treesitter_indent = true,

  -- User on_attach: project-specific keymaps
  on_attach = function(_, bufnr)
    local ok_java, java = pcall(require, "java")
    if ok_java and type(java.java_keymaps) == "function" then
      java.java_keymaps(bufnr)
    end
  end,
})
