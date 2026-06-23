local ok_dap = pcall(require, "dap")
if not ok_dap then return end

require("dap-controls").setup({
  keymaps = true,
  signs = true,
  listeners = true,
  thread_sync = true,
  repl_paste = true,
  breakpoints = true,
  dap_view = true,
  adapters = {
    java = true,
    kotlin = true,
    javascript = true,
  },
})
