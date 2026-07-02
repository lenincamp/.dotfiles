local util = require("picker.util")

local function file_filters()
  return {
    {
      key = "J",
      label = "Java",
      glob = { "*.java" },
      predicate = function(item)
        return util.path_has_extension(util.item_path(item), { ".java" })
      end,
    },
    {
      key = "j",
      label = "JS/TS",
      glob = { "*.js", "*.ts" },
      predicate = function(item)
        return util.path_has_extension(util.item_path(item), { ".js", ".ts" })
      end,
    },
    {
      key = "x",
      label = "JSX/TSX",
      glob = { "*.jsx", "*.tsx" },
      predicate = function(item)
        return util.path_has_extension(util.item_path(item), { ".jsx", ".tsx" })
      end,
    },
    {
      key = "S",
      label = "Salesforce",
      glob = {
        "force-app/**",
        "*.cls",
        "*.trigger",
        "*.page",
        "*.component",
        "*.cmp",
        "*.app",
        "*.design",
        "*.object",
        "*.field-meta.xml",
        "*.js-meta.xml",
      },
      predicate = function(item)
        local path = util.item_path(item):lower()
        return path:find("force%-app/", 1, false) ~= nil
          or util.path_has_extension(path, {
            ".cls",
            ".trigger",
            ".page",
            ".component",
            ".cmp",
            ".app",
            ".design",
            ".object",
            ".field-meta.xml",
            ".js-meta.xml",
          })
      end,
    },
    {
      key = "X",
      label = "XML",
      glob = { "*.xml" },
      predicate = function(item)
        return util.path_has_extension(util.item_path(item), { ".xml" })
      end,
    },
    {
      key = "n",
      label = "JSON",
      glob = { "*.json", "*.jsonc" },
      predicate = function(item)
        return util.path_has_extension(util.item_path(item), { ".json", ".jsonc" })
      end,
    },
    {
      key = "y",
      label = "YAML/TOML/properties",
      glob = { "*.yml", "*.yaml", "*.toml", "*.properties" },
      predicate = function(item)
        return util.path_has_extension(util.item_path(item), { ".yml", ".yaml", ".toml", ".properties" })
      end,
    },
  }
end

require("picker").setup({
  git = { commands = true },
  filters = file_filters(),
  buffer_actions = {
    ["<C-a>"] = {
      desc = "avante",
      fn = function(selected)
        local files = {}
        for _, info in ipairs(selected or {}) do
          if info and info.bufnr and vim.api.nvim_buf_is_valid(info.bufnr) then
            local path = info.name ~= "" and info.name or nil
            if path then
              files[#files + 1] = path
            end
          end
        end
        require("modules.integrations.avante.files").add_files(files)
      end,
    },
  },
  dashboard = {
    actions = {
      session = function()
        require("config.editor.sessions").restore()
      end,
    },
    on_restore_window = function(win)
      pcall(function()
        require("config.gutter").apply_window(win)
      end)
    end,
  },
})

local editor = require("config.editor")
editor.load("sessions"):setup()
editor.load("command_center")
editor.load("task_runner")
editor.load("terminal"):setup()
