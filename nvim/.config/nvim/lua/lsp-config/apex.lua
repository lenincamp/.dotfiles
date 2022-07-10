local lspconfig = require("lspconfig")
local configs = require("lspconfig.configs")
local server_setups = require("lsp-config.language-servers")
-- Check if it's already defined for when reloading this file.
if not configs.apex then
	configs.apex = {
		default_config = {
			cmd = {
				"/usr/lib/jvm/default-runtime/bin/java",
				"-cp",
				"/home/lenin/.config/lsp-apex/apex-jorje-lsp.jar",
				"-Ddebug.internal.errors=true",
				"-Ddebug.semantic.errors=false",
				"-Ddebug.completion.statistics=false",
				"-Dlwc.typegeneration.disabled=true",
				"apex.jorje.lsp.ApexLanguageServerLauncher",
			},
			filetypes = { "apex", "cls", "trigger" },
			root_dir = lspconfig.util.root_pattern(".git", "sfdx-project.json"),
			-- root_dir = function(fname)
			-- 	return lspconfig.util.find_git_ancestor(fname) or vim.loop.os_homedir()
			-- end,
			settings = {},
		},
	}
end

lspconfig.apex.setup({
	capabilities = server_setups.capabilities,
	on_attach = server_setups.custom_attach,
	autostart = not vim.api.nvim_win_get_option(0, "diff"),
})
-- vim.cmd([[ au BufNewFile,BufRead *.apxc,*.apxt,*.cls,*.trigger,*.tgr setf apex ]])
