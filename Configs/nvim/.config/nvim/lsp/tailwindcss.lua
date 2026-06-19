local allowed_filetypes = {
  html = true,
  css = true,
  scss = true,
  less = true,
  javascriptreact = true,
  typescriptreact = true,
  svelte = true,
  vue = true,
}

local root_markers = {
  "tailwind.config.js",
  "tailwind.config.ts",
  "tailwind.config.cjs",
  "tailwind.config.mjs",
}

return {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = {
    "html",
    "css",
    "scss",
    "less",
    "javascriptreact",
    "typescriptreact",
    "svelte",
    "vue",
  },
  root_dir = function(bufnr, on_dir)
    local ft = vim.bo[bufnr].filetype
    if not allowed_filetypes[ft] then
      return
    end

    local root = vim.fs.root(bufnr, root_markers)
    if not root then
      return
    end

    on_dir(root)
  end,
}
