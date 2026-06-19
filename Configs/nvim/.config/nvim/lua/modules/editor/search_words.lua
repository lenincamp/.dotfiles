local M = {}

local words_state = {
  buf = nil,
  word = nil,
}

local function reset_words_state()
  words_state.buf = nil
  words_state.word = nil
end

function M.clear_search_highlights()
  vim.cmd("nohlsearch")
  pcall(vim.lsp.buf.clear_references)
  reset_words_state()
end

function M.enable_search_highlight_and_return(key)
  if type(key) ~= "string" or key == "" then
    return ""
  end

  vim.o.hlsearch = true
  return key
end

function M.jump_word_reference(count)
  local jump_count = count or 1
  local buf = vim.api.nvim_get_current_buf()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end

  local should_refresh = words_state.buf ~= buf or words_state.word ~= word
  if should_refresh then
    words_state.buf = buf
    words_state.word = word
    pcall(vim.lsp.buf.document_highlight)
  end

  local direction = jump_count < 0 and "bW" or "W"
  local pattern = [[\V\<]] .. vim.fn.escape(word, [[\/]]) .. [[\>]]
  for _ = 1, math.abs(jump_count) do
    if vim.fn.search(pattern, direction) == 0 then
      vim.cmd(jump_count < 0 and "normal! G$" or "normal! gg0")
      vim.fn.search(pattern, direction)
    end
  end

  vim.cmd("normal! zv")
end

return M
