return {
  {
    "stevearc/oil.nvim",
    opts = function()
      require("oil").setup({
        default_file_explorer = true,
        view_options = {
          show_hidden = true,
        },
        float = {
          padding = 5,
        },
      })
    end,
    -- dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    keys = {
      { "-", "<cmd>Oil --float<CR>", desc = "Open Floating Filesystem" },
    },
  },
}
