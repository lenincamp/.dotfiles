return {
  -- buffer line
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
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
    config = function()
      local colors = require("catppuccin.palettes").get_palette("mocha")
      local theme = {
        normal = { a = { fg = colors.peach }, b = { fg = colors.blue }, c = { fg = colors.teal } },
        insert = { a = { fg = colors.blue } },
        visual = { a = { fg = colors.text } },
        replace = { a = { fg = colors.yellow } },
        command = { a = { fg = colors.red } },
        inactive = { a = { fg = colors.green }, b = { fg = colors.blue }, c = { fg = colors.green } },
      }
      require("lualine").setup({
        options = {
          icons_enabled = true,
          theme = theme,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },

  -- filename
  {
    "b0o/incline.nvim",
    -- dependencies = { "craftzdog/solarized-osaka.nvim" },
    event = "BufReadPre",
    priority = 1200,
    config = function()
      -- local colors = require("solarized-osaka.colors").setup()
      -- local helpers = require("incline.helpers")
      -- local devicons = require("nvim-web-devicons")
      require("incline").setup({
        highlight = {
          groups = {
            InclineNormal = { guibg = "#89B4FA", guifg = "#11111b" },
            InclineNormalNC = { guifg = "#11111b", guibg = "#89B4FA" },
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
          return { { icon, guifg = "#11111b" }, { " " }, { filename } }
        end,
      })
    end,
  },

  -- {
  --   "folke/zen-mode.nvim",
  --   cmd = "ZenMode",
  --   opts = {
  --     plugins = {
  --       gitsigns = true,
  --       tmux = true,
  --       kitty = { enabled = false, font = "+2" },
  --     },
  --   },
  --   keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
  -- },
}
