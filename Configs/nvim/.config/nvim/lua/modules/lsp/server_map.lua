local M = {}

local servers_by_filetype = {
  lua = { "lua_ls" },
  kotlin = { "kotlin_language_server" },
  sh = { "bashls" },
  bash = { "bashls" },
  zsh = { "bashls" },
  vim = { "vimls" },
  dockerfile = { "dockerls" },
  xml = { "lemminx" },
  markdown = { "marksman" },
  ["markdown.mdx"] = { "marksman" },
  toml = { "taplo" },
  yaml = { "yamlls" },
  ["yaml.docker-compose"] = { "docker_compose_language_service" },

  javascript = { "vtsls", "eslint", "lwc_ls" },
  javascriptreact = { "vtsls", "eslint", "tailwindcss" },
  typescript = { "vtsls", "eslint" },
  typescriptreact = { "vtsls", "eslint", "tailwindcss" },

  html = { "eslint", "tailwindcss", "lwc_ls" },
  css = { "tailwindcss" },
  scss = { "tailwindcss" },
  less = { "tailwindcss" },
  vue = { "tailwindcss" },
  svelte = { "tailwindcss" },

  apex = { "apex_ls" },
  visualforce = { "visualforce_ls" },
}

function M.for_filetype(filetype)
  return servers_by_filetype[filetype]
end

function M.all()
  return servers_by_filetype
end

return M
