local null_ls = require("null-ls")

local formatting = null_ls.builtins.formatting

local sources = {
	formatting.eslint,
	formatting.prettier.with({
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
			"css",
			"scss",
			"html",
			"json",
			"yaml",
			"markdown",
			"lwc-html",
			"apex",
		},
	}),
	-- formatting.autopep8,
	formatting.stylua,
	-- formatting.clang_format,
	null_ls.builtins.diagnostics.eslint,
	null_ls.builtins.code_actions.eslint,
	null_ls.builtins.code_actions.gitsigns,
	null_ls.builtins.diagnostics.shellcheck.with({
		diagnostics_format = "[#{c}] #{m} (#{s})",
	}),
}

-- local no_really = {
-- 	method = null_ls.methods.DIAGNOSTICS,
-- 	filetypes = { "markdown", "text", "javascript" },
-- 	generator = {
-- 		fn = function(params)
-- 			local diagnostics = {}
-- 			-- sources have access to a params object
-- 			-- containing info about the current file and editor state
-- 			for i, line in ipairs(params.content) do
-- 				local col, end_col = line:find("really")
-- 				if col and end_col then
-- 					-- null-ls fills in undefined positions
-- 					-- and converts source diagnostics into the required format
-- 					table.insert(diagnostics, {
-- 						row = i,
-- 						col = col,
-- 						end_col = end_col,
-- 						source = "no-really",
-- 						message = "Don't use 'really!'",
-- 						severity = 2,
-- 					})
-- 				end
-- 			end
-- 			return diagnostics
-- 		end,
-- 	},
-- }

-- null_ls.register(no_really)

null_ls.setup({
	sources = sources,
	-- debug = true,

	on_attach = function(client)
		if client.resolved_capabilities.document_formatting then
			vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting()")
			-- if client.resolved_capabilities.document_highlight then
			-- 	vim.api.nvim_exec(
			-- 		[[
			--          augroup document_highlight
			--          autocmd! * <buffer>
			--          autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
			--          autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
			--          augroup END
			--        ]],
			-- 		false
			-- 	)
			-- end
			-- vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 2300)")
			-- vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")

			-- vim.cmd([[
			--       augroup LspFormatting
			--       autocmd! * <buffer>
			--       autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync(nil, 2300)
			--       augroup END
			-- ]])
		end
	end,
})

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	underline = true,
	-- This sets the spacing and the prefix, obviously.
	virtual_text = {
		spacing = 4,
		prefix = "",
	},
})
