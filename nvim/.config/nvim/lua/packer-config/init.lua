return require("packer").startup(function()
	use("wbthomason/packer.nvim") --> packer plugin manager

	-->
	use("kyazdani42/nvim-web-devicons") --> enable icons
	use("norcalli/nvim-colorizer.lua")
	use("nvim-lualine/lualine.nvim") --> a statusline written in lua
	-- use("romgrk/barbar.nvim") --> tabs for neovim
	--[[ use({
		"kyazdani42/nvim-tree.lua",
		requires = {
			"kyazdani42/nvim-web-devicons", -- optional, for file icon
		},
		tag = "nightly",
	}) --> file explorer ]]
	use("lukas-reineke/indent-blankline.nvim") --> indent guides for neovim
	use("akinsho/toggleterm.nvim")
	use("nvim-lua/plenary.nvim")
	use("nvim-telescope/telescope.nvim") --> Find, Filter, Preview, Pick. All lua, all the time.
	use("numToStr/Comment.nvim")
	use("ggandor/lightspeed.nvim") --> motion plugin with incremental input processing, allowing for unparalleled speed with near-zero cognitive effort
	use("rcarriga/nvim-notify")
	use("windwp/nvim-autopairs")
	-- use("sunjon/shade.nvim") --> dim inactive windows
	use("Pocco81/TrueZen.nvim")
	use("fladson/vim-kitty") --> kitty syntax highlighting
	use("jubnzv/mdeval.nvim") --> evaluates code blocks inside markdown, vimwiki, orgmode.nvim and norg docs
	use("jbyuki/nabla.nvim")

	--> colorschemes
	use("EdenEast/nightfox.nvim") --> nightfox colorsceme for neovim
	use("sainnhe/gruvbox-material")
	use("NLKNguyen/papercolor-theme")
	use("folke/tokyonight.nvim")
	use("ishan9299/nvim-solarized-lua")

	use("nvim-neorg/neorg")

	--> treesitter & treesitter modules/plugins
	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" }) --> treesitter
	use("nvim-treesitter/nvim-treesitter-textobjects") --> textobjects
	use("nvim-treesitter/nvim-treesitter-refactor")
	use("p00f/nvim-ts-rainbow")
	use("nvim-treesitter/playground")
	use("JoosepAlviste/nvim-ts-context-commentstring")

	--> lsp
	use("neovim/nvim-lspconfig") --> Collection of configurations for built-in LSP client
	use("williamboman/nvim-lsp-installer") --> Companion plugin for lsp-config, allows us to seamlesly install language servers
	use("jose-elias-alvarez/null-ls.nvim") --> inject lsp diagnistocs, formattings, code actions, and more ...
	use("tami5/lspsaga.nvim") --> icons for LSP diagnostics
	use("onsails/lspkind-nvim") --> vscode-like pictograms for neovim lsp completion items

	-- nvim-cmp
	use({
		"hrsh7th/nvim-cmp",
		requires = {
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-path" },
			{ "hrsh7th/cmp-nvim-lua" },
			{ "ray-x/cmp-treesitter" },
			{ "hrsh7th/nvim-cmp" },
			{ "hrsh7th/cmp-vsnip" },
			{ "hrsh7th/vim-vsnip" },
			{ "Saecki/crates.nvim" },
			{ "f3fora/cmp-spell" },
			-- { "hrsh7th/cmp-cmdline" },
			{ "tamago324/cmp-zsh" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "tzachar/cmp-tabnine", run = "./install.sh", requires = "hrsh7th/nvim-cmp" },
		},
		-- config = function()
		-- 	require("joel.completion")
		-- end,
	})

	use("L3MON4D3/LuaSnip") --> Snippets plugin

	use("tpope/vim-fugitive")
	use("tpope/vim-ragtag")
	use("tpope/vim-surround")

	use("editorconfig/editorconfig-vim")
	use("dhruvmanila/telescope-bookmarks.nvim")
	use("nvim-telescope/telescope-github.nvim")
	use("cljoly/telescope-repo.nvim")
	use({
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup()
		end,
	})
	use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })
	use("jvgrootveld/telescope-zoxide")
	use({ "nvim-telescope/telescope-file-browser.nvim" })
	use({
		"lewis6991/gitsigns.nvim",
		requires = { "nvim-lua/plenary.nvim" },
	})
	use("windwp/nvim-ts-autotag")
	use("p00f/nvim-ts-rainbow")
	use("nvim-lua/popup.nvim")
	use("epilande/vim-react-snippets")

	-- use("prabirshrestha/vim-lsp")
	-- use('mattn/vim-lsp-settings')
end)
