local M = {}

function M.normalize(path)
  if type(path) ~= "string" or path == "" then
    return ""
  end

  local real = vim.uv.fs_realpath(path)
  return vim.fs.normalize(real or path)
end

function M.basename(path)
  if type(path) ~= "string" or path == "" then
    return ""
  end
  return vim.fn.fnamemodify(path, ":t")
end

function M.ensure_dir(path)
  if type(path) == "string" and path ~= "" then
    vim.fn.mkdir(path, "p")
  end
  return path
end

function M.project_root(start, markers)
  markers = markers or { "mvnw", "pom.xml", "build.gradle", "package.json", ".git" }
  local path = start or vim.api.nvim_get_current_buf()
  return vim.fs.root(path, markers) or vim.fn.getcwd()
end

function M.project_key(root)
  root = M.normalize(root or M.project_root())
  if root == "" then
    root = vim.fn.getcwd()
  end
  return vim.fn.sha256(root):sub(1, 12)
end

return M
