return {
  "mfussenegger/nvim-dap",
  config = function()
    local dapui, dapvirtualtext, dap = require("dapui"), require("nvim-dap-virtual-text"), require("dap")
    dapui.setup()
    dapvirtualtext.setup()
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    local function project_root()
      return vim.fs.root(0, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }) or vim.fn.getcwd()
    end
    dap.configurations.java = {
      {
        type = "java",
        request = "attach",
        name = "Debug (Attach) - Remote",
        hostName = "127.0.0.1",
        port = 51922,
        modulePaths = {},
        classPaths = project_root(),
        mainClass = "",
        projectName = "api",
        shortenCommandLine = "argfile",
      },
      {
        type = "java",
        name = "Current File",
        request = "launch",
        mainClass = "${file}",
        shortenCommandLine = "argfile",
        -- projectName = "api",
      },
      {
        type = "java",
        request = "attach",
        name = "Remote Attach 5005",
        hostName = "localhost",
        port = 5005,
      },
      {
        type = "java",
        name = "Debug Maven Tests",
        request = "attach",
        hostName = "127.0.0.1",
        port = 5005,
        modulePaths = {},
        classPaths = project_root(),
        mainClass = "",
        projectName = "api",
        shortenCommandLine = "argfile",
      },
    }
    if not dap.adapters.kotlin then
      dap.adapters.kotlin = {
        type = "executable",
        command = "kotlin-debug-adapter",
        options = { auto_continue_if_many_stopped = false },
      }
    end
    dap.configurations.kotlin = {
      {
        type = "kotlin",
        request = "launch",
        name = "This file",
        -- may differ, when in doubt, whatever your project structure may be,
        -- it has to correspond to the class file located at `build/classes/`
        -- and of course you have to build before you debug
        mainClass = function()
          local root = vim.fs.find("src", { path = vim.uv.cwd(), upward = true, stop = vim.env.HOME })[1] or ""
          local fname = vim.api.nvim_buf_get_name(0)
          -- src/main/kotlin/websearch/Main.kt -> websearch.MainKt
          return fname:gsub(root, ""):gsub("main/kotlin/", ""):gsub(".kt", "Kt"):gsub("/", "."):sub(2, -1)
        end,
        projectRoot = "${workspaceFolder}",
        jsonLogFile = "",
        enableJsonLogging = false,
      },
      {
        -- Use this for unit tests
        -- First, run
        -- ./gradlew --info cleanTest test --debug-jvm
        -- then attach the debugger to it
        type = "kotlin",
        request = "attach",
        name = "Attach to debugging session",
        port = 5005,
        args = {},
        projectRoot = vim.fn.getcwd,
        hostName = "localhost",
        timeout = 2000,
      },
    }
  end,
}
