local lsp_installer = require("nvim-lsp-installer")

local key_maps_on_attach = function(bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	local function buf_set_option(...)
		vim.api.nvim_buf_set_option(bufnr, ...)
	end

	buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

	local opts = { noremap = true, silent = true }

	buf_set_keymap("n", "<C-]>", ":lua vim.lsp.buf.definition()<CR>", opts) --> jumps to the definition of the symbol under the cursor
	buf_set_keymap("n", "gd", ":lua vim.lsp.buf.definition()<CR>", opts) --> jumps to the definition of the symbol under the cursor
	buf_set_keymap("n", "<leader>gh", ":lua vim.lsp.buf.hover()<CR>", opts) --> information about the symbol under the cursos in a floating window
	buf_set_keymap("n", "gi", ":lua vim.lsp.buf.implementation()<CR>", opts) --> lists all the implementations for the symbol under the cursor in the quickfix window
	-- buf_set_keymap("n", "<leader>rn", ":lua vim.lsp.util.rename()<CR>", opts) --> renaname old_fname to new_fname
	-- buf_set_keymap("n", "<C-.>", ":lua vim.lsp.buf.code_action()<CR>", opts) --> selects a code action available at the current cursor position
	-- buf_set_keymap("n", "gr", ":lua vim.lsp.buf.references()<CR>", opts) --> lists all the references to the symbl under the cursor in the quickfix window
	buf_set_keymap("n", "<leader>of", ":lua vim.diagnostic.open_float()<CR>", opts)
	-- buf_set_keymap("n", "[d", ":lua vim.diagnostic.goto_prev()<CR>", opts)
	-- buf_set_keymap("n", "]d", ":lua vim.diagnostic.goto_next()<CR>", opts)
	buf_set_keymap("n", "<leader>lq", ":lua vim.diagnostic.setloclist()<CR>", opts)
	buf_set_keymap("n", "<leader>lf", ":lua vim.lsp.buf.formatting_sync(nil, 2300)<CR>", opts) --> formats the current buffer
	buf_set_keymap("n", "gD", ":lua vim.lsp.buf.declaration()<CR>", opts) --> formats the current buffer
	buf_set_keymap("n", "<leader>gt", ":lua vim.lsp.buf.document_symbol()<CR>", opts) --> formats the current buffer
	buf_set_keymap("n", "<leader>gw", ":lua vim.lsp.buf.workspace_symbol()<CR>", opts) --> formats the current buffer

	buf_set_keymap("n", "<leader>d", "<cmd>lua require'lspsaga.provider'.preview_definition()<CR>", opts)
	buf_set_keymap("n", "gh", "<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>", opts)
	buf_set_keymap("n", "K", "<cmd>lua require('lspsaga.hover').render_hover_doc()<CR>", opts)
	buf_set_keymap("n", "<C-f>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>", opts)
	buf_set_keymap("n", "<C-b>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>", opts)
	buf_set_keymap("n", "<leader>rn", "<cmd>lua require('lspsaga.rename').rename()<CR>", opts)

	-- jump diagnostic
	buf_set_keymap("n", "<[d>", ":Lspsaga diagnostic_jump_prev<CR>", opts)
	buf_set_keymap("n", "<]d>", ":Lspsaga diagnostic_jump_next<CR>", opts)
	buf_set_keymap("n", "<leader>ca", "<cmd>lua require('lspsaga.codeaction').code_action()<CR>", opts)
	buf_set_keymap("v", "<leader>ca", ":<C-U>lua require('lspsaga.codeaction').range_code_action()<CR>", opts)
	buf_set_keymap("i", "<C-k>", "<cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>", opts)
	-- show line diagnostic
	buf_set_keymap("n", "<leader>ld", ":Lspsaga show_line_diagnostics<CR>", opts)
	-- only show diagnostic if cursor is over the area
	buf_set_keymap("n", "<leader>cd", ":Lspsaga show_cursor_diagnostics<CR>", opts)
end

local on_attach = function(client, bufnr)
	key_maps_on_attach(bufnr)
end

local servers = {
	"bashls",
	"pyright",
	"tsserver",
	"emmet_ls",
	"sumneko_lua",
	-- "ltex",
	"eslint",
	"cssls",
	"cssmodules_ls",
	"html",
	"jsonls",
	"tailwindcss",
}

---@diagnostic disable-next-line: undefined-global
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

for _, name in pairs(servers) do
	local server_is_found, server = lsp_installer.get_server(name)
	if server_is_found then
		if not server:is_installed() then
			print("Installing " .. name)
			server:install()
		end
	end
end

local isDiffMode = vim.api.nvim_win_get_option(0, "diff")
lsp_installer.on_server_ready(function(server)
	if server.name == "tsserver" or server.name == "html" then
		server:setup({
			-- root_dir = function()
			-- 	return vim.loop.cwd()
			-- end,
			capabilities = capabilities,
			autostart = not isDiffMode,
			on_attach = function(client, bufnr)
				client.resolved_capabilities.document_formatting = false
				client.resolved_capabilities.document_range_formatting = false
				key_maps_on_attach(bufnr)
			end,
		})
	else
		-- Specify the default options which we'll use to setup all servers
		local default_opts = {
			on_attach = on_attach,
			capabilities = capabilities,
			autostart = not isDiffMode,
		}

		server:setup(default_opts)
	end
end)

return { custom_attach = on_attach, capabilities = capabilities }
