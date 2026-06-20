local M = {}

function M.word()
  local word = vim.fn.expand("<cword>")
  if not word or word == "" then
    return nil
  end
  return word
end

return M
