local status, jdtls = pcall(require, "jdtls")
if not status then
  print("Error no carga jdtls")
  return
end

-- Determine OS
local os_config = "linux"
if vim.fn.has("mac") == 1 then
  os_config = "mac"
end

local home = os.getenv("HOME")
local brew_path = "/opt/homebrew/Cellar"
local jdtls_path = brew_path .. "/jdtls/1.54.0/libexec"
local java_path = brew_path .. "/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home"
local function get_jdtls()
  -- local mason_registry = require("mason-registry")
  -- local jdtls_mason = mason_registry.get_package("jdtls")
  -- local jdtls_path = jdtls_mason:get_install_path() --NOTE: present error on workpace machine
  -- local jdtls_path = "/Users/lcampoverde/Documents/projects/petersen/jdtls-1.9.0" -- homebrew path

  local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
  local config = jdtls_path .. "/config_" .. os_config
  -- local lombok = jdtls_path .. "/lombok.jar" --NOTE: temporary comment due to workpace error
  local lombok = home .. "/.config/nvim/lombok.jar"
  return launcher, config, lombok
end

local function get_bundles()
  local bundles = {
    -- vim.fn.globpath("$MASON/packages/java-debug-adapter/extension/server", "*.jar", true, true),
    vim.fn.glob("$MASON/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", 1),
  }

  vim.list_extend(bundles, vim.fn.globpath("$MASON/packages/java-test/extension/server", "*.jar", true, true))

  -- [ [ local bundles = vim.fn.glob(
  --   home
  --     .. "/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
  --   true,
  --   true
  -- ) ] ]
  --  -- local extra_bundles =
  -- --   vim.fn.glob(home .. "/.local/share/nvim/mason/packages/java-test/extension/server/*.jar", true, true)
  ---- vim.list_extend(bundles, extra_bundles)

  return bundles
end

local function get_workspace()
  local workspace_path = home .. "/.local/share/eclipse/"
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  return workspace_path .. project_name
end

local function java_keymaps(bufnr)
  vim.keymap.set(
    "n",
    "<leader>jc",
    ":lua require('config.java').create_java_class()<CR>",
    { desc = "Crear archivo Java" }
  )

  -- Mapeo de tecla para ejecutar la función en modo visual
  vim.api.nvim_set_keymap(
    "v",
    "<Leader>ec",
    ":lua require('config.java').escapar_caracteres()<CR>",
    { noremap = true, silent = true }
  )

  -- Configurar mapeo de teclas
  vim.keymap.set(
    "n",
    "<leader>Mr",
    "<Cmd>:lua require('config.java').run_test_method(false)<CR>",
    { noremap = true, silent = true, desc = "[M]aven [R]un Test Method" }
  )
  vim.keymap.set(
    "n",
    "<leader>Mc",
    "<Cmd>:lua require('config.java').run_test_class()<CR>",
    { noremap = true, silent = true, desc = "[M]aven Run Test [C]lass" }
  )
  vim.keymap.set(
    "n",
    "<leader>Md",
    "<Cmd>:lua require('config.java').run_test_method(true)<CR>",
    { noremap = true, silent = true, desc = "[M]aven [D]ebug Test Method" }
  )

  -- Java extensions provided by jdtls
  vim.keymap.set("n", "<leader>Jo", jdtls.organize_imports, { desc = "[J]ava [O]rganize Imports" })
  vim.keymap.set("n", "<leader>Jv", jdtls.extract_variable, { desc = "[J]ava Extract [V]ariable" })
  vim.keymap.set(
    "v",
    "<leader>Jv",
    "<Cmd>lua require('jdtls').extract_variable({ visual = true })<CR>",
    { desc = "[J]ava Extract [V]ariable" }
  )
  vim.keymap.set("n", "<leader>Jc", jdtls.extract_constant, { desc = "[J]ava Extract [C]onstant" })
  vim.keymap.set(
    "v",
    "<leader>Jc",
    "<Cmd>lua require('jdtls').extract_constant({ visual = true })<CR>",
    { desc = "[J]ava Extract [C]onstant" }
  )

  vim.keymap.set(
    "v",
    "<leader>Jm",
    [[<ESC><CMD>lua require('jdtls').extract_method({ visual = true })<CR>]],
    { noremap = true, silent = true, buffer = bufnr, desc = "[J]ava Extract [M]ethod" }
  )

  --vsc test
  vim.keymap.set("n", "<leader>JC", jdtls.test_class, { desc = "[J]ava Test [C]lass" })
  vim.keymap.set("n", "<leader>Jt", jdtls.test_nearest_method, { desc = "[J]ava [T]est Method" })
  vim.keymap.set("n", "<leader>Jp", jdtls.pick_test, { desc = "[J]ava [P]ick Test" })
  vim.keymap.set("n", "<leader>Ju", "<Cmd>JdtUpdateConfig<CR>", { desc = "[J]ava [U]pdate Config" })

  if vim.api.nvim_buf_is_valid(bufnr) then
    -- nvim-dap
    vim.keymap.set("n", "<leader>dbl", function()
      require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
    end, { desc = "Set log point" })
    vim.keymap.set("n", "<leader>br", function()
      require("dap").clear_breakpoints()
    end, { desc = "Clear breakpoints" })
    vim.keymap.set("n", "<leader>dd", function()
      require("dap").disconnect()
    end, { desc = "Disconnect" })
    vim.keymap.set("n", "<leader>dt", function()
      require("dap").terminate()
    end, { desc = "Terminate" })
  end
end

local on_attach = function(_, bufnr)
  vim.lsp.codelens.refresh()
  jdtls.setup_dap({ hotcodereplace = "auto" })
  local status_ok, jdtls_dap = pcall(require, "jdtls.dap")
  if status_ok then
    -- jdtls_dap.setup_dap({ hotcodereplace = "auto" })
    jdtls_dap.setup_dap_main_class_configs()
  end
  java_keymaps(bufnr)
end

local function get_capabilities()
  local capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("blink.cmp").get_lsp_capabilities()
  )
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" },
  }
  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
  -- extendedClientCapabilities.onCompletionItemSelectedCommand = "editor.action.triggerParameterHints"
  return capabilities, extendedClientCapabilities
end

local launcher, jdtls_os_config, lombok = get_jdtls()
local capabilities, extendedClientCapabilities = get_capabilities()
-- local java_24 = "/opt/homebrew/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home"
local config = {
  cmd = {
    java_path .. "/bin/java",
    -- "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home/bin/java",
    -- "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-XX:+UseParallelGC",
    "-Dfile.encoding=UTF-8",
    "-XX:GCTimeRatio=1",
    "-XX:AdaptiveSizePolicyWeight=90",
    "-Dsun.zip.disableMemoryMapping=true",
    "-Xmx4G",
    "-Xms512m",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "--add-opens",
    "java.base/sun.nio.fs=ALL-UNNAMED",
    "-javaagent:" .. lombok,
    "-jar",
    launcher,
    "-configuration",
    jdtls_os_config,
    "-data",
    get_workspace(),
  },
  root_dir = jdtls.setup.find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
  capabilities = capabilities,
  settings = {
    java = {
      -- extendedClientCapabilities = extendedClientCapabilities,
      eclipse = {
        downloadSources = true,
      },
      format = {
        enabled = true,
        settings = {
          url = home .. "/.config/nvim/PetersenStyle.xml",
          profile = "GoogleStyle",
        },
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" }, -- Use fernflower to decompile library code
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
        importOrder = {
          "java",
          "jakarta",
          "javax",
          "com",
          "org",
        },
      },
      -- extendedClientCapabilities = extendedClientCapabilities,
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true,
      },
      configuration = {
        updateBuildConfiguration = "interactive",
        runtimes = {
          {
            name = "Java-17",
            path = home .. "Library/Java/JavaVirtualMachines/azul-17.0.10/Contents/Home",
            default = true,
          },
          {
            name = "Java-21",
            path = brew_path .. "/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home",
          },
          {
            name = "Java-1.8",
            path = "/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home",
          },
        },
      },
      maven = {
        downloadSources = true,
      },
      grade = {
        enabled = true,
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        parameterNames = {
          enabled = "all", -- literals, all, none
        },
      },
    },
  },
  flags = {
    debounce_text_changes = 80,
    allow_incremental_sync = true,
  },
  on_attach = on_attach,
  init_options = {
    bundles = get_bundles(),
    extendedClientCapabilities = extendedClientCapabilities,
  },
}

jdtls.start_or_attach(config)
