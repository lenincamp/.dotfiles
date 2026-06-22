local PROJECT_MARKERS = { ".yamllint", ".yamllint.yaml", ".yamllint.yml" }

local function has_schema_modeline(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, math.min(20, vim.api.nvim_buf_line_count(bufnr)), false)
  for _, line in ipairs(lines) do
    if line:find("yaml%-language%-server:%s*%$schema=") then
      return true
    end
  end
  return false
end

local function is_known_yaml(path)
  local name = vim.fn.fnamemodify(path, ":t")
  return name == ".gitlab-ci.yml"
    or name == ".gitlab-ci.yaml"
    or name == "Chart.yaml"
    or name == "values.yaml"
    or path:find("/%.github/workflows/[^/]+%.yml$") ~= nil
    or path:find("/%.github/workflows/[^/]+%.yaml$") ~= nil
end

return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml" },
  root_dir = function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      return
    end

    local root = vim.fs.root(bufnr, PROJECT_MARKERS)
    if root or has_schema_modeline(bufnr) or is_known_yaml(path) then
      on_dir(root or vim.fs.root(bufnr, { ".git" }) or vim.fs.dirname(path))
    end
  end,
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      format = { enable = true },
      hover = true,
      completion = true,
      validate = true,
      schemaStore = { enable = true },
    },
  },
}