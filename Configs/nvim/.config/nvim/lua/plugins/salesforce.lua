return {
  "jonathanmorris180/salesforce.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("salesforce").setup({})
  end,
}
