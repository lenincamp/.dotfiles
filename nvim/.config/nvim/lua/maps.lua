local keymap = vim.keymap

keymap.set('n', 'x', '"_x')

-- Increment/decrement
keymap.set('n', '+', '<C-a>')
keymap.set('n', '-', '<C-x>')

-- Delete a word backwards
keymap.set('n', 'dw', 'vb"_d')

-- Select all
keymap.set('n', '<C-a>', 'gg<S-v>G')

-- Save with root permission (not working for now)
--vim.api.nvim_create_user_command('W', 'w !sudo tee > /dev/null %', {})

--delete current buffer
keymap.set("n", "<Leader>q", ":bd<CR>")
-- Move to first symbol on the line
keymap.set("n", "H", "^")
-- Move to last symbol of the line
keymap.set("n", "L", "$")
-- Yank to end of line
keymap.set("n", "Y", "y$")

-- New tab
keymap.set('n', 'te', ':tabedit')
--keymap.set("n", "<C-n>", ":tabnew<CR>")
keymap.set("n", "tc", ":tabclose<CR>")
-- Split window
keymap.set('n', 'ss', ':split<Return><C-w>w')
keymap.set('n', 'sv', ':vsplit<Return><C-w>w')
-- Move window
keymap.set('n', '<Space>', '<C-w>w')
keymap.set('', 'sh', '<C-w>h')
keymap.set('', 'sk', '<C-w>k')
keymap.set('', 'sj', '<C-w>j')
keymap.set('', 'sl', '<C-w>l')

-- Resize window
keymap.set('n', '<C-w><left>', '<C-w><')
keymap.set('n', '<C-w><right>', '<C-w>>')
keymap.set('n', '<C-w><up>', '<C-w>+')
keymap.set('n', '<C-w><down>', '<C-w>-')
-- Auto indent pasted text
--keymap.set("n", "p", "p=`]<C-o>")
--keymap.set("n", "p", "P=`]<C-o>")
-- Indenting in visual mode (tab/shift+tab)
keymap.set("v", "<Tab>", ">gv")
keymap.set("v", "<S-Tab>", "<gv")
-- Space + Space to clean search highlight
keymap.set("n", "<leader>h", ":noh<CR>")
-- Fixes pasting after visual selection.
keymap.set("x", "p", '"_dP')
-- Switch to last file
keymap.set("n", "<Leader><Leader>", "<c-^>")
-- Copy the relative path of the current file to the clipboard
keymap.set("n", "<Leader>cf", ":silent !echo -n % | pbcopy<Enter>")
--"""Config save
keymap.set("n", "<Leader>w", ":w<CR>")
keymap.set("n", "Q", ":q<CR>")
keymap.set("n", "Qa", ":qa<CR>")
keymap.set("n", "QQ", ":q!<CR>")
keymap.set("n", "QA", ":qa!<CR>")
--" Mover lineas
keymap.set("n", "<S-Up>", ":m-2<CR>")
keymap.set("n", "<S-Down>", ":m+<CR>")

--Salesforce maps
keymap.set("n", "<F9>", ":!sfdx force:source:retrieve -p %:p<CR>")
keymap.set("n", "<F10>", ":!sfdx force:source:deploy -p '%:p'<CR>")
keymap.set("n", "<F11>", ":!sfdx force:apex:test:run --tests %:t:r.<cword> -r human<CR>")
keymap.set("n", "<F12>", ":!sfdx force:apex:test:run --classnames %:t:r --codecoverage -r human<CR>")


function _G.set_terminal_keymaps()
  local opts = { noremap = true }
  vim.api.nvim_buf_set_keymap(0, "t", "<esc>", [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "sh", [[<C-\><C-n><C-W>h]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "sj", [[<C-\><C-n><C-W>j]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "sk", [[<C-\><C-n><C-W>k]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "sl", [[<C-\><C-n><C-W>l]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
