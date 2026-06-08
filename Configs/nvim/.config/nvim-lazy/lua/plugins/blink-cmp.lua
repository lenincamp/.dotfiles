return {
  "saghen/blink.cmp",
  optional = true,
  lazy = true,
  opts = {
    sources = {
      providers = {
        path = {
          enabled = function()
            return vim.bo.filetype ~= "copilot-chat"
          end,
        },
      },
    },
  },
}
