local M = {}

local pair_map = {
  ["("] = ")",
  ["["] = "]",
  ["{"] = "}",
  ['"'] = '"',
  ["'"] = "'",
  ["`"] = "`",
}

local closing = {
  [")"] = true,
  ["]"] = true,
  ["}"] = true,
}

local function feed(keys)
  return keys
end

local function next_char()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  return line:sub(col + 1, col + 1)
end

local function prev_char()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  return line:sub(col, col)
end

local function open_pair(char)
  if vim.bo.filetype == "Avante" then
    return char
  end
  local close = pair_map[char]
  if not close then
    return char
  end

  if char == '"' or char == "'" or char == "`" then
    if next_char() == char then
      return feed("<Right>")
    end
    if prev_char():match("[%w_]") then
      return char
    end
  end

  return char .. close .. feed("<Left>")
end

local function close_pair(char)
  if vim.bo.filetype == "Avante" then
    return char
  end
  if next_char() == char then
    return feed("<Right>")
  end
  return char
end

local function backspace()
  if vim.bo.filetype == "Avante" then
    return feed("<C-h>")
  end
  local prev = prev_char()
  local next = next_char()
  if pair_map[prev] == next then
    return feed("<BS><Del>")
  end
  return feed("<BS>")
end

function M.setup()
  for open in pairs(pair_map) do
    vim.keymap.set("i", open, function()
      return open_pair(open)
    end, { expr = true, desc = "Insert pair " .. open })
  end

  for close in pairs(closing) do
    vim.keymap.set("i", close, function()
      return close_pair(close)
    end, { expr = true, desc = "Close pair " .. close })
  end

  vim.keymap.set("i", "<BS>", backspace, { expr = true, desc = "Smart pair backspace" })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("pure_pairs_avante_passthrough", { clear = true }),
    pattern = "Avante",
    callback = function(args)
      for lhs in pairs(pair_map) do
        vim.keymap.set("i", lhs, lhs, { buffer = args.buf, nowait = true, desc = "Avante passthrough " .. lhs })
      end
      for lhs in pairs(closing) do
        vim.keymap.set("i", lhs, lhs, { buffer = args.buf, nowait = true, desc = "Avante passthrough " .. lhs })
      end
      vim.keymap.set("i", "<BS>", "<C-h>", { buffer = args.buf, nowait = true, desc = "Avante backspace" })
    end,
  })
end

return M
