local COMPOSE_FILES = {
  ["compose.yaml"] = true,
  ["compose.yml"] = true,
  ["docker-compose.yaml"] = true,
  ["docker-compose.yml"] = true,
}

return {
  filetypes = { "yaml.docker-compose" },
  root_dir = function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      return
    end

    if COMPOSE_FILES[vim.fn.fnamemodify(path, ":t")] then
      on_dir(vim.fs.dirname(path))
    end
  end,
}