local colors = require("catppuccin.palettes").get_palette(vim.o.background == "dark" and "mocha" or "latte")

local function has_real_split()
  local real = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    -- skip floating windows
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == "" then
      -- skip quickfix/loclist/popup
      local wnr = vim.fn.win_id2win(win)
      if vim.fn.win_gettype(wnr) == "" then
        -- count only normal file buffers
        local buf = vim.api.nvim_win_get_buf(win)
        local bt = vim.api.nvim_buf_get_option(buf, "buftype")
        local mod = vim.api.nvim_buf_get_option(buf, "modifiable")
        if bt == "" and mod then
          real = real + 1
        end
      end
    end
  end
  return real > 1
end

return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    lazy = true,
    priority = 1000,
    enabled = false,
    opts = {
      options = {
        -- mode = "tabs",
        -- separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
        custom_filter = function()
          return false
        end,

        -- Evita texto residual
        name_formatter = function()
          return ""
        end,
        always_show_bufferline = false,
        custom_areas = {
          right = function()
            local result = {}
            for i = 1, vim.fn.tabpagenr("$") do
              local name = vim.fn.gettabvar(i, "tab_name", "")
              if name ~= "" then
                table.insert(result, {
                  text = " " .. name .. " ",
                  fg = colors.peach,
                })
              end
            end
            return result
          end,
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = false,
    optional = true,
    event = "VeryLazy",
    config = function()
      local lualine_c = {}

      table.insert(lualine_c, {
        "filename",
        path = 1,
        cond = function()
          return not has_real_split()
        end,
      })
      table.insert(lualine_c, {
        "filename",
        cond = has_real_split,
      })
      table.insert(lualine_c, {
        "require'salesforce.org_manager':get_default_alias()",
        icon = "󰢎",
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
        winbar = {
          lualine_c = {
            {
              "filename",
              path = 1,
              symbols = {
                modified = " ●",
                readonly = " 🔒",
              },
              cond = has_real_split,
            },
          },
        },
        inactive_winbar = {
          lualine_c = {
            {
              "filename",
              path = 1,
              symbols = {
                modified = " ●",
                readonly = " 🔒",
              },
              cond = has_real_split,
            },
          },
        },
      })
    end,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        styles = {
          transparency = true,
        },
      })
    end,
  },
  {
    "vague-theme/vague.nvim",
    lazy = true, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other plugins
    config = function()
      require("vague").setup({
        transparent = true,
      })
    end,
  },
  -- {
  --   "b0o/incline.nvim",
  --   event = "BufReadPre",
  --   priority = 1200,
  --   config = function()
  --     -- represent filename as tab
  --     require("incline").setup({
  --       highlight = {
  --         groups = {
  --           InclineNormal = { guifg = colors.peach },
  --           InclineNormalNC = { guifg = colors.peach },
  --         },
  --       },
  --       window = { margin = { vertical = 0, horizontal = 1 } },
  --       hide = {
  --         cursorline = true,
  --       },
  --       render = function(props)
  --         local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
  --         if vim.bo[props.buf].modified then
  --           filename = "[+] " .. filename
  --         end
  --         local icon, color = require("nvim-web-devicons").get_icon_color(filename)
  --         return { { icon, guifg = colors.peach }, { " " }, { filename } }
  --       end,
  --     })
  --   end,
  -- },
}
