return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      -- your explorer configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      -- layout = { preview = "false", preset = "ivy" },
    },
    picker = {
      sources = {
        explorer = {
          layout = { preview = "false", preset = "ivy" },
          -- your explorer picker configuration comes here
          -- or leave it empty to use the default settings
        },
      },
    },
  },
}
