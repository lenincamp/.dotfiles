local status, luasnip = pcall(require, "luasnip")
if (not status) then return end
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_snipmate").lazy_load()
require("luasnip.loaders.from_vscode").lazy_load({ paths = { "~/.config/nvim/snippets/salesforce" } })
luasnip.filetype_extend("all", { "_" })
