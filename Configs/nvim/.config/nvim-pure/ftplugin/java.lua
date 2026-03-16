-- Java ftplugin: JDTLS setup optimised for IntelliJ-like experience.
-- Key features: Lombok, DAP, treesitter indent, Spring Boot helpers,
-- full semantic analysis, code generation, and decompiled source navigation.

-- Skip JDTLS in diff mode (git difftool, vimdiff, etc.)
if vim.wo.diff then return end

local ok_jdtls, jdtls = pcall(require, "jdtls")
if not ok_jdtls then return end

local ok_blink, blink = pcall(require, "blink.cmp")
if not ok_blink then return end

-- ── Paths ──────────────────────────────────────────────────────────────────────

local home      = os.getenv("HOME")
local brew_base = "/opt/homebrew/Cellar"

-- Mason: prefer nvim-pure own, fall back to main nvim
local function resolve_mason_base()
  local own  = vim.fn.stdpath("data") .. "/mason/packages/"
  local main = home .. "/.local/share/nvim/mason/packages/"
  return vim.fn.isdirectory(own .. "java-debug-adapter") == 1 and own or main
end
local mason_base = resolve_mason_base()

-- ── Root & Workspace ───────────────────────────────────────────────────────────

local root_dir = jdtls.setup.find_root({ "mvnw", "gradlew", "pom.xml", "build.gradle", ".git" })
if root_dir == nil then return end

local project_name  = vim.fn.fnamemodify(root_dir, ":t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. project_name

-- ── DAP bundles ────────────────────────────────────────────────────────────────

local bundles = {}
vim.list_extend(bundles, vim.fn.glob(
  mason_base .. "java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
  false, true))
vim.list_extend(bundles, vim.fn.glob(
  mason_base .. "java-test/extension/server/*.jar",
  false, true))

-- ── Lombok agent ───────────────────────────────────────────────────────────────

local lombok_jar = home .. "/.local/share/nvim/mason/packages/jdtls/lombok.jar"
if vim.fn.filereadable(lombok_jar) == 0 then
  local candidates = vim.fn.glob(
    home .. "/.m2/repository/org/projectlombok/lombok/*/lombok-*.jar", false, true)
  lombok_jar = (#candidates > 0) and candidates[#candidates] or ""
end

-- ── JVM command ────────────────────────────────────────────────────────────────

local cmd = { "jdtls", "-data", workspace_dir }
if lombok_jar ~= "" and vim.fn.filereadable(lombok_jar) == 1 then
  -- Only -javaagent is needed for Lombok on Java 9+.
  -- -Xbootclasspath/a is deprecated since Java 9 and causes
  -- NoClassDefFoundError for javax.annotation.processing.AbstractProcessor
  -- on Java 11+, which breaks JDTLS capability registration entirely.
  table.insert(cmd, 2, "--jvm-arg=-javaagent:" .. lombok_jar)
end

-- ── Format style ───────────────────────────────────────────────────────────────

local style_file = home .. "/.config/nvim-pure/SofiProjectsStyle.xml"
if vim.fn.filereadable(style_file) == 0 then
  style_file = home .. "/.config/nvim/SofiProjectsStyle.xml"
end

-- ── Extended capabilities (CRITICAL for IntelliJ parity) ──────────────────────
-- Enables: semantic tokens, decompiler, move refactoring, override detection,
-- advanced code actions (generate getters/setters/constructors), progress reports.
-- extendedClientCapabilities enables the full IntelliJ-like feature set:
--   classFileContentsSupport     → navigate into decompiled .class sources
--   moveRefactoringSupport       → Move class/method refactoring
--   overrideMethodsPromptSupport → Override dialog like IntelliJ
--   generateToStringPromptSupport, hashCodeEqualsPromptSupport, etc.
local ext_caps = vim.deepcopy(jdtls.extendedClientCapabilities)

-- ── Config ─────────────────────────────────────────────────────────────────────

local config = {
  cmd          = cmd,
  root_dir     = root_dir,
  capabilities = blink.get_lsp_capabilities(),

  -- Faster document sync; allow_incremental_sync reduces CPU on large files
  flags = {
    debounce_text_changes  = 150,
    allow_incremental_sync = true,
  },

  -- extendedClientCapabilities must be in init_options, NOT settings
  init_options = {
    bundles                    = bundles,
    extendedClientCapabilities = ext_caps,
  },

  settings = {
    java = {

      -- ── Sources & decompiler ──────────────────────────────────────────────
      eclipse       = { downloadSources = true },
      maven         = { downloadSources = true, updateSnapshots = true },
      gradle        = { enabled = true, downloadSources = true },
      contentProvider = { preferred = "fernflower" },  -- best decompiler
      references    = { includeDecompiledSources = true },

      -- ── Indexing & build ──────────────────────────────────────────────────
      autobuild = { enabled = true },   -- rebuild on save (like IntelliJ auto-make)
      maxConcurrentBuilds = 4,          -- parallel compilation units

      -- Exclude noise from project indexing (speeds up initial scan)
      import = {
        exclusions = {
          "**/node_modules/**",
          "**/.metadata/**",
          "**/archetype-resources/**",
          "**/META-INF/maven/**",
        },
        maven  = { enabled = true },
        gradle = { enabled = true },
      },

      configuration = {
        updateBuildConfiguration = "automatic",  -- was "interactive" — auto-update
        runtimes = {
          {
            name = "JavaSE-1.8",
            path = "/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home",
          },
          {
            name = "JavaSE-11",
            path = brew_base .. "/openjdk@11/11.0.30/libexec/openjdk.jdk/Contents/Home",
          },
          {
            name = "JavaSE-17",
            path = "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home",
          },
          {
            name    = "JavaSE-21",
            path    = brew_base .. "/openjdk@21/21.0.10/libexec/openjdk.jdk/Contents/Home",
            default = true,
          },
        },
      },

      -- ── Completion (IntelliJ-style) ───────────────────────────────────────
      signatureHelp = { enabled = true, description = { enabled = true } },

      completion = {
        enabled          = true,
        overwrite        = false,     -- insert, not overwrite existing word
        guessMethodArguments = true,  -- auto-fill method arg types
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*",
          "org.mockito.ArgumentMatchers.*",
          "java.util.stream.Collectors.*",
          "java.util.Arrays.*",
          "java.util.Collections.*",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
        importOrder = { "java", "jakarta", "javax", "com", "org" },
      },

      -- ── Format ───────────────────────────────────────────────────────────
      format = {
        enabled  = true,
        comments = { enabled = true },
        settings = {
          url     = style_file,
          profile = "Patagonia-Style",
        },
      },

      -- ── Code lens (like IntelliJ gutter icons) ───────────────────────────
      implementationsCodeLens = { enabled = true },
      referencesCodeLens      = { enabled = true },

      -- ── Inlay hints (IntelliJ parameter hints) ────────────────────────────
      inlayHints = {
        parameterNames = {
          enabled          = "all",      -- show for all methods
          exclusions       = {},
        },
      },

      -- ── Save actions (like IntelliJ "Optimize Imports on save") ──────────
      saveActions = {
        organizeImports = true,          -- auto-organize imports on save
      },

      -- ── Source paths ──────────────────────────────────────────────────────
      sources = {
        organizeImports = {
          starThreshold       = 9999,
          staticStarThreshold = 9999,
        },
      },

      -- ── Code generation templates ─────────────────────────────────────────
      codeGeneration = {
        toString = {
          template    = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
          codeStyle   = "STRING_CONCATENATION",
          skipNullValues = false,
          listArrayContents = true,
        },
        hashCodeEquals = {
          useJava7Objects   = true,
          useInstanceof     = true,
        },
        useBlocks        = true,
        addFinalForNewDeclaration = false,
        insertionLocation = "afterCursor",
      },

      -- ── Diagnostics ────────────────────────────────────────────────────────
      -- null-analysis: find NullPointerException risks at analysis time
      -- (requires annotations like @NonNull / @Nullable in the classpath)
      project = {
        referencedLibraries = { "lib/**/*.jar" },
      },

    },
  },

  -- ── on_attach ──────────────────────────────────────────────────────────────

  on_attach = function(_, bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    -- DAP main-class launcher
    local ok_dap, jdtls_dap = pcall(require, "jdtls.dap")
    if ok_dap then
      jdtls_dap.setup_dap_main_class_configs({
        config_overrides = {
          vmArgs      = "-Xmx2g -XX:+UseG1GC",
          console     = "integratedTerminal",
          stopOnEntry = false,
          stepFilters = {
            skipClasses = {},
            skipSynthetics = false,
            skipConstructors = false,
            skipStaticInitializers = false,
          },
        },
      })
    end

    -- Java utility keymaps (test runners, DAP, Snacks explorer, …)
    local ok_java, java = pcall(require, "java")
    if ok_java then java.java_keymaps(bufnr) end
  end,

  -- Test runner JVM flags
  test = {
    config_overrides = { vmArgs = "-ea -Xmx1g" },
  },
}

jdtls.start_or_attach(config)

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

-- Quick shortcuts
map("<leader>Ji", jdtls.organize_imports, "Java: organize imports")
map("<leader>Jv", jdtls.extract_variable, "Java: extract variable")
map("<leader>Jm", jdtls.extract_method,   "Java: extract method")

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

-- ── Java file creator ─────────────────────────────────────────────────────────
--
-- Prompt syntax (single input):
--   ClassName           → same package as current file
--   .sub.ClassName      → sub-package relative to current package
--   com.pkg.ClassName   → absolute package (last segment = class name)
--
-- Package is read from the buffer's `package` declaration first,
-- then inferred from the file path, and left empty when neither applies.

local function current_package()
  -- 1. Read declaration from buffer (most reliable, handles any path layout)
  if vim.bo.filetype == "java" then
    local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
    for _, line in ipairs(lines) do
      local pkg = line:match("^%s*package%s+([%w%.]+)%s*;")
      if pkg then return pkg end
    end
  end
  -- 2. Infer from src/main|test/java path
  local cur = vim.fn.expand("%:p")
  return (cur:match("src/main/java/(.+)/[^/]+%.java$")
    or cur:match("src/test/java/(.+)/[^/]+%.java$") or ""):gsub("/", ".")
end

local function current_src_root()
  local cur = vim.fn.expand("%:p")
  return cur:match("^(.*src/main/java/)")
    or cur:match("^(.*src/test/java/)")
    or (vim.fs.root(0, { "pom.xml", "gradlew", "build.gradle" }) or vim.fn.getcwd())
      .. "/src/main/java/"
end

-- Split "com.example.ClassName" → ("com.example", "ClassName")
local function split_last(s)
  local dot = s:match(".*()%.")
  if dot then return s:sub(1, dot - 1), s:sub(dot + 1) end
  return "", s
end

local function parse_input(input, base_pkg)
  if input:sub(1, 1) == "." then
    -- Relative: ".ClassName" or ".sub.ClassName"
    local rest = input:sub(2)
    local sub_pkg, name = split_last(rest)
    if name == "" then name, sub_pkg = sub_pkg, "" end  -- only one segment
    local pkg = (base_pkg ~= "" and sub_pkg ~= "") and (base_pkg .. "." .. sub_pkg)
      or (base_pkg ~= "" and base_pkg)
      or sub_pkg
    return pkg, name
  elseif input:find("%.") then
    -- Absolute: "com.example.ClassName"
    return split_last(input)
  else
    -- Simple: "ClassName"
    return base_pkg, input
  end
end

local function create_java_file(type_kw, boilerplate_fn)
  local base_pkg = current_package()
  local src_root = current_src_root()
  local hint     = base_pkg ~= "" and ("[" .. base_pkg .. "] ") or "[no package] "

  vim.ui.input({
    prompt = type_kw .. " " .. hint .. "(Name · .sub.Name · pkg.Name): ",
  }, function(input)
    if not input or input == "" then return end

    local final_pkg, name = parse_input(input, base_pkg)

    if not name:match("^[A-Z][%w_]*$") then
      vim.notify("Name must be PascalCase: " .. name, vim.log.levels.ERROR)
      return
    end

    local target_dir = src_root .. final_pkg:gsub("%.", "/")
    vim.fn.mkdir(target_dir, "p")

    local filepath = target_dir .. "/" .. name .. ".java"
    if vim.fn.filereadable(filepath) == 1 then
      vim.notify(type_kw .. " already exists: " .. filepath, vim.log.levels.WARN)
      return
    end

    vim.fn.writefile(boilerplate_fn(final_pkg, name), filepath)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    local loc = final_pkg ~= "" and final_pkg or "(default package)"
    vim.notify("Created: " .. name .. ".java  [" .. loc .. "]", vim.log.levels.INFO)
  end)
end

local function pkg_header(pkg)
  return pkg ~= "" and { "package " .. pkg .. ";", "" } or {}
end

map("<leader>Jtc", function()
  create_java_file("class", function(pkg, name)
    local lines = pkg_header(pkg)
    vim.list_extend(lines, { "public class " .. name .. " {", "", "}" })
    return lines
  end)
end, "Spring: Create class")

map("<leader>Jtn", function()
  create_java_file("interface", function(pkg, name)
    local lines = pkg_header(pkg)
    vim.list_extend(lines, { "public interface " .. name .. " {", "", "}" })
    return lines
  end)
end, "Spring: Create interface")

map("<leader>Jte", function()
  create_java_file("enum", function(pkg, name)
    local lines = pkg_header(pkg)
    vim.list_extend(lines, { "public enum " .. name .. " {", "", "}" })
    return lines
  end)
end, "Spring: Create enum")

-- Spring Boot run
map("<leader>Jtr", function()
  local root = vim.fs.root(0, { "pom.xml", "build.gradle", "build.gradle.kts" })
    or vim.fn.getcwd()
  local run_cmd
  if vim.fn.filereadable(root .. "/pom.xml") == 1 then
    run_cmd = "cd " .. vim.fn.shellescape(root) .. " && mvn spring-boot:run"
  else
    run_cmd = "cd " .. vim.fn.shellescape(root) .. " && ./gradlew bootRun"
  end
  vim.cmd("botright 15split | terminal " .. run_cmd)
  vim.cmd("startinsert")
end, "Spring: Run project")
