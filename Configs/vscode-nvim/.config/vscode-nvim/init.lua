local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    -- bootstrap lazy.nvim
    -- stylua: ignore
    vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
                   lazypath})
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)
require("lazy").setup({
	{ "tpope/vim-surround" },
	{ "tpope/vim-repeat" },
	{ "justinmk/vim-sneak" },
	{ "vscode-neovim/vscode-multi-cursor.nvim" },
	{ "folke/flash.nvim" },
})
require("vscode-multi-cursor").setup({ -- Config is optional
	-- Whether to set default mappings
	default_mappings = true,
	-- If set to true, only multiple cursors will be created without multiple selections
	no_selection = false,
})

local whichkey = {
	show = function()
		vim.fn.VSCodeNotify("whichkey.show")
	end,
}

local comment = {
	selected = function()
		vim.fn.VSCodeNotifyRange("editor.action.commentLine", vim.fn.line("v"), vim.fn.line("."), 1)
	end,
}

local commentblock = {
	selected = function()
		vim.fn.VSCodeNotifyRange("editor.action.blockComment", vim.fn.line("v"), vim.fn.line("."), 1)
	end,
}

local file = {
	new = function()
		vim.fn.VSCodeNotify("workbench.explorer.fileView.focus")
		vim.fn.VSCodeNotify("explorer.newFile")
	end,

	save = function()
		vim.fn.VSCodeNotify("workbench.action.files.save")
	end,

	saveAll = function()
		vim.fn.VSCodeNotify("workbench.action.files.saveAll")
	end,

	format = function()
		vim.fn.VSCodeNotify("editor.action.formatDocument")
	end,

	showInExplorer = function()
		vim.fn.VSCodeNotify("workbench.files.action.showActiveFileInExplorer")
	end,

	rename = function()
		vim.fn.VSCodeNotify("workbench.files.action.showActiveFileInExplorer")
		vim.fn.VSCodeNotify("renameFile")
	end,
}

local error = {
	list = function()
		vim.fn.VSCodeNotify("workbench.actions.view.problems")
	end,
	next = function()
		vim.fn.VSCodeNotify("editor.action.marker.next")
	end,
	previous = function()
		vim.fn.VSCodeNotify("editor.action.marker.prev")
	end,
}

local editor = {
	closeActive = function()
		vim.fn.VSCodeNotify("workbench.action.closeActiveEditor")
	end,

	closeOther = function()
		vim.fn.VSCodeNotify("workbench.action.closeOtherEditors")
	end,

	organizeImport = function()
		vim.fn.VSCodeNotify("editor.action.organizeImports")
	end,

	codeAction = function()
		vim.fn.VSCodeNotify("editor.action.quickFix")
	end,
	triggerParameterHints = function()
		vim.fn.VSCodeNotify("editor.action.triggerParameterHints")
	end,
}

local workbench = {
	showCommands = function()
		vim.fn.VSCodeNotify("workbench.action.showCommands")
	end,
	previousEditor = function()
		vim.fn.VSCodeNotify("workbench.action.previousEditor")
	end,
	nextEditor = function()
		vim.fn.VSCodeNotify("workbench.action.nextEditor")
	end,
}

local toggle = {
	toggleActivityBar = function()
		vim.fn.VSCodeNotify("workbench.action.toggleActivityBarVisibility")
	end,
	toggleSideBarVisibility = function()
		vim.fn.VSCodeNotify("workbench.action.toggleSidebarVisibility")
	end,
	toggleZenMode = function()
		vim.fn.VSCodeNotify("workbench.action.toggleZenMode")
	end,
	theme = function()
		vim.fn.VSCodeNotify("workbench.action.selectTheme")
	end,
}

local symbol = {
	rename = function()
		vim.fn.VSCodeNotify("editor.action.rename")
	end,
}

-- if bookmark extension is used
local bookmark = {
	toggle = function()
		vim.fn.VSCodeNotify("bookmarks.toggle")
	end,
	list = function()
		vim.fn.VSCodeNotify("bookmarks.list")
	end,
	previous = function()
		vim.fn.VSCodeNotify("bookmarks.jumpToPrevious")
	end,
	next = function()
		vim.fn.VSCodeNotify("bookmarks.jumpToNext")
	end,
}

local search = {
	reference = function()
		vim.fn.VSCodeNotify("editor.action.referenceSearch.trigger")
	end,
	referenceInSideBar = function()
		vim.fn.VSCodeNotify("references-view.find")
	end,
	project = function()
		vim.fn.VSCodeNotify("editor.action.addSelectionToNextFindMatch")
		vim.fn.VSCodeNotify("workbench.action.findInFiles")
	end,
	text = function()
		vim.fn.VSCodeNotify("workbench.action.findInFiles")
	end,
}

local project = {
	findFile = function()
		vim.fn.VSCodeNotify("workbench.action.quickOpen")
	end,
	switch = function()
		vim.fn.VSCodeNotify("workbench.action.openRecent")
	end,
}

local git = {
	init = function()
		vim.fn.VSCodeNotify("git.init")
	end,
	status = function()
		vim.fn.VSCodeNotify("workbench.view.scm")
	end,
	switch = function()
		vim.fn.VSCodeNotify("git.checkout")
	end,
	deleteBranch = function()
		vim.fn.VSCodeNotify("git.deleteBranch")
	end,
	push = function()
		vim.fn.VSCodeNotify("git.push")
	end,
	pull = function()
		vim.fn.VSCodeNotify("git.pull")
	end,
	fetch = function()
		vim.fn.VSCodeNotify("git.fetch")
	end,
	commit = function()
		vim.fn.VSCodeNotify("git.commit")
	end,
	publish = function()
		vim.fn.VSCodeNotify("git.publish")
	end,

	-- if gitlens installed
	graph = function()
		vim.fn.VSCodeNotify("gitlens.showGraphPage")
	end,
}

local fold = {
	toggle = function()
		vim.fn.VSCodeNotify("editor.toggleFold")
	end,

	all = function()
		vim.fn.VSCodeNotify("editor.foldAll")
	end,
	openAll = function()
		vim.fn.VSCodeNotify("editor.unfoldAll")
	end,

	close = function()
		vim.fn.VSCodeNotify("editor.fold")
	end,
	open = function()
		vim.fn.VSCodeNotify("editor.unfold")
	end,
	openRecursive = function()
		vim.fn.VSCodeNotify("editor.unfoldRecursively")
	end,

	blockComment = function()
		vim.fn.VSCodeNotify("editor.foldAllBlockComments")
	end,

	allMarkerRegion = function()
		vim.fn.VSCodeNotify("editor.foldAllMarkerRegions")
	end,
	openAllMarkerRegion = function()
		vim.fn.VSCodeNotify("editor.unfoldAllMarkerRegions")
	end,
}

local vscode = {
	focusEditor = function()
		vim.fn.VSCodeNotify("workbench.action.focusActiveEditorGroup")
	end,
	moveSideBarRight = function()
		vim.fn.VSCodeNotify("workbench.action.moveSideBarRight")
	end,
	moveSideBarLeft = function()
		vim.fn.VSCodeNotify("workbench.action.moveSideBarLeft")
	end,
}

local refactor = {
	showMenu = function()
		vim.fn.VSCodeNotify("editor.action.refactor")
	end,
}

local extensions = {
	toggleBool = function()
		vim.fn.VSCodeNotify("extension.toggleBool")
	end,
}

-- https://vi.stackexchange.com/a/31887
local nv_keymap = function(lhs, rhs)
	vim.api.nvim_set_keymap("n", lhs, rhs, {
		noremap = true,
		silent = true,
	})
	vim.api.nvim_set_keymap("v", lhs, rhs, {
		noremap = true,
		silent = true,
	})
end

local nx_keymap = function(lhs, rhs)
	vim.api.nvim_set_keymap("n", lhs, rhs, {
		silent = true,
	})
	vim.api.nvim_set_keymap("v", lhs, rhs, {
		silent = true,
	})
end

-- #region keymap
vim.g.mapleader = " "
vim.notify = vscode.notify
vim.cmd("nmap <leader>e :e ~/.config/vscode-nvim/init.lua<cr>")
-- paste without overwriting
vim.keymap.set({ "v" }, "p", "P")
-- vim.keymap.set({ "n", "x", "i" }, "<C-d>", function()
-- 	vim.fn.VSCodeNotify("editor.action.addSelectionToNextFindMatch")
-- end)

-- split
vim.cmd("nmap <leader>ss :sp<cr>")
vim.cmd("nmap <leader>sv :vsp<cr>")
vim.cmd("nmap <leader>q :q<cr>")
-- encoding
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.expandtab = true
vim.opt.wildignore:append({ "*/node_modules/*" })
-- vim.cmd("set nocompatible")
-- Mostrar números relativos
vim.opt.relativenumber = true
-- Habilitar autoindentación
vim.opt.autoindent = true
-- Habilitar smartindentación
vim.opt.smartindent = true
-- Habilitar el uso del ratón
vim.opt.mouse = "a"
-- Deshabilitar el modo compatible
vim.opt.compatible = false
-- Ignorar mayúsculas/minúsculas en las búsquedas
vim.opt.ignorecase = true
-- Habilitar la opción smartcase para las búsquedas
vim.opt.smartcase = true
-- Añadir '**' al path para buscar archivos en subdirectorios
vim.opt.path:append({ "**" })
-- Habilitar el menú de autocompletado
vim.opt.wildmenu = true
-- Habilitar la sintaxis
vim.cmd("syntax enable")
-- Y fix
vim.keymap.set({ "n" }, "Y", "y$")
vim.keymap.set({ "v" }, "am", "aBoV")
vim.keymap.set({ "n" }, "]<leader>", "o<Esc>k")
vim.keymap.set({ "n" }, "[<leader>", "O<Esc>j")

vim.opt.clipboard = "unnamedplus"
-- fix errors
vim.keymap.set({ "n", "v" }, "<leader>ca", editor.codeAction)
vim.keymap.set({ "n", "v" }, "<leader>i", extensions.toggleBool)
-- vim.keymap.set({ "i" }, "<C-k>", editor.triggerParameterHints)
-- inoremap <C-k> <Cmd>lua require('vscode').action('editor.action.triggerParameterHints')<CR>
vim.api.nvim_set_keymap("n", "<C-j>", "<Cmd>lua require('vscode').action('editor.action.moveLinesDownAction')<CR>", {
	noremap = true,
	silent = true,
})
vim.api.nvim_set_keymap("n", "<C-k>", "<Cmd>lua require('vscode').action('editor.action.moveLinesUpAction')<CR>", {
	noremap = true,
	silent = true,
})

local cursors = require("vscode-multi-cursor")
vim.keymap.set({ "n", "x", "i" }, "<C-n>", function()
	cursors.addSelectionToNextFindMatch()
end)
vim.keymap.set({ "n", "x", "i" }, "<CS-n>", function()
	cursors.addSelectionToPreviousFindMatch()
end)
vim.keymap.set({ "n", "x", "i" }, "<CS-l>", function()
	cursors.selectHighlights()
end)
vim.keymap.set("n", "<c-n>", "mciw*:nohl<cr>", {
	remap = true,
})

--[[ vim.api.nvim_set_hl(0, 'FlashLabel', {
    bg = '#e11684',
    fg = 'white'
})

vim.api.nvim_set_hl(0, 'FlashMatch', {
    bg = '#7c634c',
    fg = 'white'
})

vim.api.nvim_set_hl(0, 'FlashCurrent', {
    bg = '#7c634c',
    fg = 'white'
}) ]]

nv_keymap("H", "^")
nv_keymap("L", "$")

-- fix fold
nx_keymap("j", "gj")
nx_keymap("k", "gk")

vim.keymap.set({ "n", "v" }, "<leader>", whichkey.show)
vim.keymap.set({ "n", "v" }, "gcc", comment.selected)
vim.keymap.set({ "v" }, "gb", commentblock.selected)

vim.keymap.set({ "n" }, "<leader>o", editor.organizeImport)

-- no highlight
vim.keymap.set({ "n" }, "<Esc>", "<cmd>noh<cr>")

vim.keymap.set({ "n", "v" }, "<leader> ", workbench.showCommands)

vim.keymap.set({ "n", "v" }, "<leader>h", workbench.previousEditor)
vim.keymap.set({ "n", "v" }, "<leader>l", workbench.nextEditor)

-- error
vim.keymap.set({ "n" }, "<leader>el", error.list)
vim.keymap.set({ "n" }, "<leader>en", error.next)
vim.keymap.set({ "n" }, "<leader>ep", error.previous)

-- git
vim.keymap.set({ "n" }, "<leader>gb", git.switch)
vim.keymap.set({ "n" }, "<leader>gi", git.init)
vim.keymap.set({ "n" }, "<leader>gd", git.deleteBranch)
vim.keymap.set({ "n" }, "<leader>gf", git.fetch)
vim.keymap.set({ "n" }, "<leader>gs", git.status)
vim.keymap.set({ "n" }, "<leader>gp", git.pull)
vim.keymap.set({ "n" }, "<leader>gg", git.graph)

-- project
vim.keymap.set({ "n" }, "<leader>pf", project.findFile)
vim.keymap.set({ "n" }, "<leader>pp", project.switch)
vim.keymap.set("n", "\\\\", "<Cmd>lua require('vscode').action('workbench.action.showAllEditors')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "gD", "<Cmd>lua require('vscode').action('editor.action.revealDefinitionAside')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "<leader>ds", "<Cmd>lua require('vscode').action('workbench.action.showAllSymbols')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "<leader>pd", "<Cmd>lua require('vscode').action('editor.action.peekDefinition')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "<leader>pi", "<Cmd>lua require('vscode').action('editor.action.peekImplementation')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "<leader>pl", "<Cmd>lua require('vscode').action('editor.action.peekLocations')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "<leader>rp", "<Cmd>lua require('vscode').action('editor.action.refactor.preview')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "]c", "<Cmd>lua require('vscode').action('workbench.action.editor.nextChange')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "[c", "<Cmd>lua require('vscode').action('workbench.action.editor.previousChange')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "]e", "<Cmd>lua require('vscode').action('editor.action.marker.next')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "[e", "<Cmd>lua require('vscode').action('editor.action.marker.prev')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "]d", "<Cmd>lua require('vscode').action('workbench.action.compareEditor.nextChange')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "[d", "<Cmd>lua require('vscode').action('workbench.action.compareEditor.previousChange')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "u", "<Cmd>lua require('vscode').action('undo')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", "<C-r>", "<Cmd>lua require('vscode').action('redo')<CR>", {
	noremap = true,
	silent = true,
})

-- file
-- vim.keymap.set({ "n", "v" }, "<C-s>", file.saveAll)
vim.keymap.set({ "n", "v" }, "<C-s>", function()
	vim.fn.VSCodeNotify("workbench.action.files.saveAll")
end, { silent = true, noremap = true })
vim.keymap.set({ "n", "v" }, "<leader>w", file.save)
vim.keymap.set({ "n" }, "<leader>ff", file.format)
vim.keymap.set({ "n" }, "<leader>fn", file.new)
vim.keymap.set({ "n" }, "<leader>sf", file.showInExplorer)
vim.keymap.set({ "n" }, "<leader>fr", file.rename)

-- buffer/editor
vim.keymap.set({ "n", "v" }, "<leader>k", editor.closeOther)

-- toggle
vim.keymap.set({ "n", "v" }, "<leader>ta", toggle.toggleActivityBar)
vim.keymap.set({ "n", "v" }, "<leader>tz", toggle.toggleZenMode)
vim.keymap.set({ "n", "v" }, "<leader>ts", toggle.toggleSideBarVisibility)
vim.keymap.set({ "n", "v" }, "<leader>tt", toggle.theme)
vim.keymap.set("n", "<leader>tb", "<Cmd>lua require('vscode').action('editor.debug.action.toggleBreakpoint')<CR>", {
	noremap = true,
	silent = true,
})

-- refactor
vim.keymap.set({ "v" }, "<leader>r", refactor.showMenu)
vim.keymap.set({ "n" }, "<leader>rr", symbol.rename)

-- bookmark
vim.keymap.set({ "n" }, "<leader>m", bookmark.toggle)
vim.keymap.set({ "n" }, "<leader>mt", bookmark.toggle)
vim.keymap.set({ "n" }, "<leader>ml", bookmark.list)
vim.keymap.set({ "n" }, "<leader>mn", bookmark.next)
vim.keymap.set({ "n" }, "<leader>mp", bookmark.previous)

vim.keymap.set({ "n" }, "<leader>sr", search.reference)
vim.keymap.set({ "n" }, "<leader>sR", search.referenceInSideBar)
vim.keymap.set({ "n" }, "<leader>sp", search.project)
vim.keymap.set({ "n" }, "<leader>st", search.text)
vim.keymap.set("n", "<leader>f", "<Cmd>lua require('vscode').action('find-it-faster.findFiles')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", ",r", "<Cmd>lua require('vscode').action('find-it-faster.findWithinFiles')<CR>", {
	noremap = true,
	silent = true,
})
vim.keymap.set("n", ",f", "<Cmd>lua require('vscode').action('find-it-faster.findWithinFilesWithType')<CR>", {
	noremap = true,
	silent = true,
})

-- vscode
vim.keymap.set({ "n" }, "<leader>ve", vscode.focusEditor)
vim.keymap.set({ "n" }, "<leader>vl", vscode.moveSideBarLeft)
vim.keymap.set({ "n" }, "<leader>vr", vscode.moveSideBarRight)

-- folding
vim.keymap.set({ "n" }, "zr", fold.openAll)
vim.keymap.set({ "n" }, "zO", fold.openRecursive)
vim.keymap.set({ "n" }, "zo", fold.open)
vim.keymap.set({ "n" }, "zm", fold.all)
vim.keymap.set({ "n" }, "zb", fold.blockComment)
vim.keymap.set({ "n" }, "zc", fold.close)
vim.keymap.set({ "n" }, "zg", fold.allMarkerRegion)
vim.keymap.set({ "n" }, "zG", fold.openAllMarkerRegion)
vim.keymap.set({ "n" }, "za", fold.toggle)
-- #endregion keymap
-- Highlight copied text (yanked text) inside VSCode Neovim
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		-- "Visual" works reliably in VSCode
		vim.highlight.on_yank({
			higroup = "Visual",
			timeout = 120, -- 120–200 ms is ideal for VSCode
		})
	end,
})
