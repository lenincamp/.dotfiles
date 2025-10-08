return {
  "xixiaofinland/sf.nvim",
  lazy = true,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "ibhagwan/fzf-lua",
  },

  config = function()
    require("sf").setup() -- Important to call setup() to initialize the plugin!
  end,
}
