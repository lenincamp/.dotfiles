local ok, rm = pcall(require, "render-markdown")
if not ok then return end

rm.setup({
  file_types = { "markdown", "Avante" },
  code = {
    sign      = false,
    width     = "block",
    right_pad = 1,
  },
  heading = {
    sign  = false,
    icons = {},
  },
  checkbox = { enabled = false },
  latex    = { enabled = false },
})

