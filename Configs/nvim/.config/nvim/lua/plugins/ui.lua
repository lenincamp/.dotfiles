local colors = require("catppuccin.palettes").get_palette(vim.o.background == "dark" and "mocha" or "latte")
local function get_sf_alias(sf_module)
  if sf_module and sf_module.get_default_alias then
    return sf_module.get_default_alias() or ""
  end
  return ""
end

local sf_org_manager = nil

local function load_salesforce_module()
  local project_root = vim.fn.resolve(vim.fn.getcwd())
  local sf_project_file = project_root .. "/sfdx-project.json"

  if vim.fn.filereadable(sf_project_file) == 1 then
    local ok, sf = pcall(require, "salesforce.org_manager")
    if ok then
      return sf
    else
      vim.notify("Error al cargar salesforce.org_manager: " .. tostring(sf), vim.log.levels.ERROR)
    end
  end
  return nil
end
return {
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
    event = "VeryLazy",
    config = function()
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
          lualine_c = {
            "filename",
            {
              "require'salesforce.org_manager':get_default_alias()",
              icon = "󰢎",
            },
          },
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
      sf_org_manager = load_salesforce_module()
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
          local alias = get_sf_alias(sf_org_manager)
          local icon, color = require("nvim-web-devicons").get_icon_color(filename)
          local alias_component = {}
          if alias ~= "" then
            table.insert(alias_component, { "󰢎 " .. alias, guifg = "#fab387" })
          end
          return vim.list_extend({ { icon, guifg = colors.peach }, { " " }, { filename } }, alias_component)
        end,
      })
    end,
  },
}
