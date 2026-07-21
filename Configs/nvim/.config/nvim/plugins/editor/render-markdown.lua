local ok, rm = pcall(require, "render-markdown")
if not ok then
  return
end

rm.setup({
  completions = { lsp = { enabled = true }, blink = { enabled = true } },
  file_types = { "markdown", "Avante" },
  latex = { enabled = false },
})
