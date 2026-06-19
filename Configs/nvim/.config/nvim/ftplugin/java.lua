-- Java ftplugin: JDTLS setup optimised for IntelliJ-like experience.
-- Key features: Lombok, DAP, treesitter indent, Spring Boot helpers,
-- full semantic analysis, code generation, and decompiled source navigation.

-- Skip JDTLS in diff mode (git difftool, vimdiff, etc.)
if vim.wo.diff then return end
if vim.bo.buftype ~= "" then return end
if vim.api.nvim_buf_get_name(0) == "" then return end

local runtime = require("modules.core.runtime")

if not runtime.load_pack("nvim-jdtls") then return end
runtime.load_pack("blink.lib")
runtime.load_pack("blink.cmp")

local ok_jdtls, jdtls = pcall(require, "jdtls")
if not ok_jdtls then return end

local ok_blink, blink = pcall(require, "blink.cmp")

local java_actions = require("lang.java.actions")
local java_jdtls_settings = require("lang.java.jdtls_settings")
local java_paths = require("lang.java.paths")

-- ── Paths ──────────────────────────────────────────────────────────────────────

local mason_base = java_paths.resolve_mason_base()

-- ── Root & Workspace ───────────────────────────────────────────────────────────

local root_dir = jdtls.setup.find_root({ "mvnw", "gradlew", "pom.xml", "build.gradle", ".git" })
if root_dir == nil then return end

local normalize_root = java_paths.normalize_root

local workspace_dir, project_name, normalized_root_dir = java_paths.workspace_for_root(root_dir)
if normalized_root_dir ~= "" then
  root_dir = normalized_root_dir
end
vim.g.nvim_pure_java_project_name = project_name

-- ── DAP bundles ────────────────────────────────────────────────────────────────

local bundles = {}
vim.list_extend(bundles, vim.fn.glob(
  mason_base .. "java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
  false, true))
vim.list_extend(bundles, vim.fn.glob(
  mason_base .. "java-test/extension/server/*.jar",
  false, true))

-- ── Lombok agent ───────────────────────────────────────────────────────────────

local lombok_jar = java_paths.lombok_jar()

-- ── JVM command ────────────────────────────────────────────────────────────────

local cmd = {
    "jdtls",
    "-vmargs",
    "-Xms512m",
    "-Xmx3G",
    "-XX:+UseG1GC",
    "-XX:MaxGCPauseMillis=200",
    "-XX:+UseStringDeduplication",
    "-data",
    workspace_dir
}
if lombok_jar ~= "" and vim.fn.filereadable(lombok_jar) == 1 then
  -- Only -javaagent is needed for Lombok on Java 9+.
  -- -Xbootclasspath/a is deprecated since Java 9 and causes
  -- NoClassDefFoundError for javax.annotation.processing.AbstractProcessor
  -- on Java 11+, which breaks JDTLS capability registration entirely.
  table.insert(cmd, 2, "--jvm-arg=-javaagent:" .. lombok_jar)
end

-- ── Format style ───────────────────────────────────────────────────────────────

local style_file = java_paths.style_file()

-- ── Extended capabilities (CRITICAL for IntelliJ parity) ──────────────────────
-- Enables: semantic tokens, decompiler, move refactoring, override detection,
-- advanced code actions (generate getters/setters/constructors), progress reports.
-- extendedClientCapabilities enables the full IntelliJ-like feature set:
--   classFileContentsSupport     → navigate into decompiled .class sources
--   moveRefactoringSupport       → Move class/method refactoring
--   overrideMethodsPromptSupport → Override dialog like IntelliJ
--   generateToStringPromptSupport, hashCodeEqualsPromptSupport, etc.
local ext_caps = vim.deepcopy(jdtls.extendedClientCapabilities)
local capabilities = ok_blink and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()

-- JDTLS can request watchers for paths that may not exist in some projects,
-- which can surface as watch ENOENT notifications in Neovim.
capabilities.workspace = capabilities.workspace or {}
capabilities.workspace.didChangeWatchedFiles = capabilities.workspace.didChangeWatchedFiles or {}
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

-- ── Config ─────────────────────────────────────────────────────────────────────
local config = {
  cmd          = cmd,
  root_dir     = root_dir,
  capabilities = capabilities,

  -- Faster document sync; allow_incremental_sync reduces CPU on large files
  flags = {
    debounce_text_changes  = 300,
    allow_incremental_sync = true,
  },

  -- extendedClientCapabilities must be in init_options, NOT settings
  init_options = {
    bundles                    = bundles,
    extendedClientCapabilities = ext_caps,
  },

  settings = java_jdtls_settings.build(style_file, java_paths.runtimes()),

  -- ── on_attach ──────────────────────────────────────────────────────────────

  on_attach = function(client, bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    -- Disable expensive semantic tokens
    client.server_capabilities.semanticTokensProvider = nil

    -- Disable inlay hints if enabled
    if client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
    end
    -- Java utility keymaps (test runners, DAP, file navigation, ...)
    local ok_java, java = pcall(require, "java")
    if ok_java and type(java.java_keymaps) == "function" then
        java.java_keymaps(bufnr)
    end

  end,

  -- Test runner JVM flags
  test = {
    config_overrides = { vmArgs = "-ea -Xmx1g" },
  },
}

local function reuse_same_root_jdtls(client, candidate)
  if not client or client.name ~= "jdtls" then
    return false
  end

  local client_root = normalize_root(client.config and client.config.root_dir)
  local candidate_root = normalize_root(candidate and candidate.root_dir)
  if client_root == "" or candidate_root == "" then
    return false
  end

  return client_root == candidate_root
end

jdtls.start_or_attach(config, nil, {
  reuse_client = reuse_same_root_jdtls,
})

-- ── Indentation: nvim-treesitter AFTER built-in indent/java.vim ───────────────

vim.schedule(function()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.bo[buf].filetype ~= "java"      then return end
  if vim.treesitter.query.get("java", "indents") ~= nil then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end)

-- ── Buffer-local keymaps ──────────────────────────────────────────────────────

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = 0, silent = true, desc = desc })
end

-- Invert condition / local variable (JDTLS refactor.rewrite code action)
-- Place cursor on the `if` condition or a boolean variable to invoke.
map("<leader>JI", function()
  vim.lsp.buf.code_action({
    filter = function(a)
      local t = (a.title or ""):lower()
      return t:find("invert") ~= nil
    end,
    apply = true,
  })
end, "Java: Invert condition")

-- <leader>Jt  Tools/JDTLS submenu
map("<leader>Jti", jdtls.organize_imports,       "JDTLS: Organize imports")
map("<leader>Jtv", jdtls.extract_variable,       "JDTLS: Extract variable")
map("<leader>Jtm", jdtls.extract_method,         "JDTLS: Extract method")
map("<leader>Jtu", "<Cmd>JdtUpdateConfig<CR>",   "JDTLS: Update config")
map("<leader>Jtw", function()
  vim.fn.delete(workspace_dir, "rf")
  vim.notify("Cleaned JDTLS workspace — restart Neovim to re-index", vim.log.levels.INFO)
end, "JDTLS: Clean workspace")

java_actions.map_keymaps(map)
