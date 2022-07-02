require("lualine").setup({
	options = {
		-- section_separators = { left = " ", right = " " },
		-- component_separators = "",
		-- theme = 'tokyonight'
		-- theme = "nightfox",
		theme = "auto",
		component_separators = { left = "|", right = "|" },
		section_separators = { left = "", right = "" },
		icons_enabled = true,
	},
	sections = {
		lualine_a = { { "mode", upper = true } },
		lualine_b = { --[[ { "branch", icon = "" } ]]
			-- "buffers",
		},
		lualine_c = { { "filename", file_status = true, path = 1 } },
		lualine_x = {
			"diff",

			{
				"diagnostics",
				sources = { "nvim_lsp" },
				symbols = { error = " ", warn = " ", info = " ", hint = " " },
			},
			"encoding",
			"fileformat",
			"filetype",
		},
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
})
