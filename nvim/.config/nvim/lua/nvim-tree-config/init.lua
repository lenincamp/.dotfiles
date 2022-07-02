require("nvim-tree").setup({
	auto_close = true,
	diagnostics = {
		enable = true,
	},
	view = {
		auto_resize = true,
		width = 45,
		side = "right",
		hide_root_folder = false,
		allow_resize = true,
		auto_close = true,
	},
	sort_by = "name",
})
