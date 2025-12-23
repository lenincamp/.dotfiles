local colors = require("catppuccin.palettes").get_palette(vim.o.background == "dark" and "mocha" or "latte")
return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    lazy = true,
    keys = {
      { "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        mode = "tabs",
        -- separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    config = function()
      local lualine_c = {}
      table.insert(lualine_c, {
        "filename",
        {
          "require'salesforce.org_manager':get_default_alias()",
          icon = "󰢎",
        },
      })

      table.insert(lualine_c, {
        function()
          return " "
        end,
        color = function()
          local status = require("sidekick.status").get()
          if status then
            if status.kind == "Error" then
              return "DiagnosticError"
            elseif status.busy then
              return "DiagnosticWarn"
            else
              return "Special"
            end
          end
        end,
        cond = function()
          --write a function fibonacci in lua
          return require("sidekick.status").get() ~= nil
        end,
      })

      table.insert(lualine_c, {
        function()
          local status = require("sidekick.status").cli()
          return " " .. (#status > 1 and #status or "")
        end,
        cond = function()
          return #require("sidekick.status").cli() > 0
        end,
        color = function()
          return "Special"
        end,
      })

      local theme = {
        normal = { a = { fg = colors.peach }, b = { fg = colors.blue }, c = { fg = colors.teal } },
        insert = { a = { fg = colors.blue } },
        visual = { a = { fg = colors.text } },
        replace = { a = { fg = colors.yellow } },
        command = { a = { fg = colors.red } },
        inactive = { a = { fg = colors.green }, b = { fg = colors.blue }, c = { fg = colors.green } },
      }
      require("lualine").setup({
        sections = {
          lualine_c = lualine_c,
        },
        options = {
          icons_enabled = true,
          theme = theme,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },
  {
    "b0o/incline.nvim",
    event = "BufReadPre",
    priority = 1200,
    config = function()
      -- represent filename as tab
      require("incline").setup({
        highlight = {
          groups = {
            InclineNormal = { guifg = colors.peach },
            InclineNormalNC = { guifg = colors.peach },
          },
        },
        window = { margin = { vertical = 0, horizontal = 1 } },
        hide = {
          cursorline = true,
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if vim.bo[props.buf].modified then
            filename = "[+] " .. filename
          end
          local icon, color = require("nvim-web-devicons").get_icon_color(filename)
          return { { icon, guifg = colors.peach }, { " " }, { filename } }
        end,
      })
    end,
  },
}
