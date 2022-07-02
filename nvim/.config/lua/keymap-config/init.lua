local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

vim.g.mapleader = " " -- leader key

--> nvim tree mappings <--
map("n", "<leader>t", ":NvimTreeToggle<CR>", opts)
map("n", "<leader>tf", ":NvimTreeFocus<CR>", opts)
map("n", "<leader>tff", ":NvimTreeFindFile<CR>", opts)
--> telescope mappings <--
-- map("n", "<leader>ff", ":Telescope find_files<cr>", opts)
-- map("n", "<leader>fg", ":Telescope live_grep<cr>", opts)
-- map("n", "<leader>fb", ":Telescope buffers<cr>", opts)
--> barbar mappings <--
--map("n", "<A-,>", ":BufferPrevious<CR>", opts)
--map("n", "<A-.>", ":BufferNext<CR>", opts)
--map("n", "<A-<>", ":BufferMovePrevious<CR>", opts)
--map("n", "<A->>", ":BufferMoveNext<CR>", opts)
--map("n", "<A-1>", ":BufferGoto 1<CR>", opts)
--map("n", "<A-2>", ":BufferGoto 2<CR>", opts)
--map("n", "<A3>", ":BufferGoto 3<CR>", opts)
--map("n", "<A-4>", ":BufferGoto 4<CR>", opts)
--map("n", "<A-5>", ":BufferGoto 5<CR>", opts)
--map("n", "<A-6>", ":BufferGoto 6<CR>", opts)
--map("n", "<A-7>", ":BufferGoto 7<CR>", opts)
--map("n", "<A-8>", ":BufferGoto 8<CR>", opts)
--map("n", "<A-9>", ":BufferGoto 9<CR>", opts)
--map("n", "<A-0>", ":BufferLast<CR>", opts)
map("n", "<Leader>q", ":bd<CR>", opts)
-- map("n", "<C-p>", ":BufferPick<CR>", opts)
--map("n", "<leader>bb", ":BufferOrderByBufferNumber<CR>", opts)
--map("n", "<leader>bd", ":BufferOrderByDirectory<CR>", opts)
--map("n", "<leader>bl", ":BufferOrderByLanguage<CR>", opts)
--> TrueZen mappings <--
map("n", "<leader>za", ":TZAtaraxis<CR>", opts)
--> nabla
map("n", "<F5>", ':lua require("nabla").action()<CR>', opts)
map("n", "<leader>np", ':lua require("nabla").popup()<CR>', opts)

--move into tabs buffers
map("n", "<leader>k", ":bnext<CR>", opts)
map("n", "<leader>j", ":bprev<CR>", opts)
-- map("n", "<leader>d", ':bdelete<CR>', opts)

-- Move to first symbol on the line
map("n", "H", "^", opts)

-- Move to last symbol of the line
map("n", "L", "$", opts)
map("n", "Y", "y$", opts)

-- Use ctrl-[hjkl] to select the active split!
map("n", "<C-k>", ":wincmd k<CR>", opts)
map("n", "<C-j>", ":wincmd j<CR>", opts)
map("n", "<C-h>", ":wincmd h<CR>", opts)
map("n", "<C-l>", ":wincmd l<CR>", opts)
map("n", "<leader>mh", ":wincmd h<CR>", opts)
map("n", "<leader>ml", ":wincmd l<CR>", opts)

-- vv - Makes vertical split
map("n", "<leader>vv", ":vsp<CR>", opts)
-- ss - Makes horizontal split
map("n", "<leader>ss", ":sp<CR>", opts)

-- close all windows, leaving :only the current window open
map("v", "<C-S-W>", "<C-w>o", opts)

-- Auto indent pasted text
map("n", "p", "p=`]<C-o>", opts)
map("n", "p", "P=`]<C-o>", opts)
-- Indenting in visual mode (tab/shift+tab)
map("v", "<Tab>", ">gv", opts)
map("v", "<S-Tab>", "<gv", opts)

-- Move to the end of yanked text after yank and paste
map("n", "p", "p`]", opts)
map("v", "y", "y`]", opts)
map("v", "p", "p`]", opts)
-- Space + o to focus buffer between others
map("n", "<leader>o", ":only<CR>", opts)

-- Space + Space to clean search highlight
map("n", "<leader>h", ":noh<CR>", opts)

-- Fixes pasting after visual selection.
map("x", "p", '"_dP', opts)

-- Switch to last file
map("n", "<Leader><Leader>", "<c-^>", opts)

-- Copy the relative path of the current file to the clipboard
map("n", "<Leader>cf", ":silent !echo -n % | pbcopy<Enter>", opts)

--"""Config save
map("n", "<Leader>w", ":w<CR>", opts)
map("n", "Q", ":q<CR>", opts)
map("n", "Qa", ":qa<CR>", opts)
map("n", "QQ", ":q!<CR>", opts)
map("n", "QA", ":qa!<CR>", opts)

--" Mover lineas
map("n", "<S-Up>", ":m-2<CR>", opts)
map("n", "<S-Down>", ":m+<CR>", opts)
--" select all
map("n", "<C-a>", "ggVG", opts)
--" Resize splits
map("n", "<C-S-Left>", ":vertical resize +1<CR>", opts)
map("n", "<C-S-Right>", ":vertical resize -1<CR>", opts)
map("n", "<C-S-Down>", ":resize -1<CR>", opts)
map("n", "<C-S-Up>", ":resize +1<CR>", opts)

--" tile all open buffers in vertical panes - http://www.vimbits.com/bits/375
map("n", "<leader>a", ":vertical :ball<cr>", opts)
--" close buffer and goto next
map("n", "<C-n>", ":tabnew<CR>", opts)
map("n", "<C-w>", ":tabclose<CR>", opts)

-- imap <silent><expr> <C-Space> compe#complete()
-- imap <silent><expr> <CR>      compe#confirm('<CR>')
-- imap <silent><expr> <C-e>     compe#close('<C-e>')
-- imap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
-- imap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
map("n", "<F9>", ":!sfdx force:source:retrieve -p %:p<CR>", opts)
map("n", "<F10>", ":!sfdx force:source:deploy -p '%:p'<CR>", opts)
map("n", "<F11>", ":!sfdx force:apex:test:run --tests %:t:r.<cword> -r human<CR>", opts)
map("n", "<F12>", ":!sfdx force:apex:test:run --classnames %:t:r --codecoverage -r human<CR>", opts)

function _G.set_terminal_keymaps()
	local opts = { noremap = true }
	vim.api.nvim_buf_set_keymap(0, "t", "<esc>", [[<C-\><C-n>]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "jk", [[<C-\><C-n>]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
