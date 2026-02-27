return {
  { "tpope/vim-surround", vscode = true },
  { "tpope/vim-repeat", vscode = true },
  { "justinmk/vim-sneak", vscode = true },
  {
    "vscode-neovim/vscode-multi-cursor.nvim",
    vscode = true,
    config = function()
      require("vscode-multi-cursor").setup({
        default_mappings = true,
        no_selection = false,
      })
    end,
  },
  { "folke/flash.nvim", vscode = true },
}
