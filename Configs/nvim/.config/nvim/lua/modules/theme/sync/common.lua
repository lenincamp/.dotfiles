local M = {}

function M.sanitize_key(key)
  return (key or "theme"):gsub("[^a-zA-Z0-9%-_]+", "-")
end

function M.write_lines(path, lines)
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(lines, path)
end

function M.read_text_file(path)
  if vim.fn.filereadable(path) ~= 1 then return nil end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then return nil end
  return table.concat(lines, "\n") .. "\n"
end

function M.write_text_file_if_changed(path, text)
  if type(text) ~= "string" then return false end
  local current = M.read_text_file(path)
  if current == text then return false end
  M.write_lines(path, vim.split(text, "\n", { plain = true }))
  return true
end

function M.copy_text_file_if_changed(src, dst)
  if vim.fn.filereadable(src) ~= 1 then return false end
  local ok_read_src, src_lines = pcall(vim.fn.readfile, src)
  if not ok_read_src or type(src_lines) ~= "table" then return false end

  local src_text = table.concat(src_lines, "\n")
  local dst_text = ""
  if vim.fn.filereadable(dst) == 1 then
    local ok_read_dst, dst_lines = pcall(vim.fn.readfile, dst)
    if ok_read_dst and type(dst_lines) == "table" then
      dst_text = table.concat(dst_lines, "\n")
    end
  end

  if src_text == dst_text then return false end
  M.write_lines(dst, src_lines)
  return true
end

return M
