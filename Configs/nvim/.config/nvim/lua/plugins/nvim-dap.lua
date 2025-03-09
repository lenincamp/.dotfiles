return {
  {
    "nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      {
        "williamboman/mason.nvim",
        opts = { ensure_installed = { "java-debug-adapter", "java-test" } },
      },
    },
    opts = function()
      -- Auto abrir/cerrar UI cuando se inicia/termina la depuración
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

      dap.configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Debug (Attach) - Remote",
          hostName = "127.0.0.1",
          port = 51922,
          modulePaths = {},
          classPaths = { "/Users/lcampoverde/Documents/projects/petersen/ar-petersen-cdp" },
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
          request = "launch",
          name = "Attach to port 5005",
          port = 5005,
          shortenCommandLine = "argfile",
        },
        {
          type = "java",
          name = "Debug Maven Tests",
          request = "attach",
          hostName = "127.0.0.1",
          port = 5005,
          modulePaths = {},
          classPaths = { "/Users/lcampoverde/Documents/projects/petersen/ar-petersen-cdp" },
          mainClass = "",
          projectName = "api",
          shortenCommandLine = "argfile",
        },
      }
      -- dap.continue()
    end,
  },
}
