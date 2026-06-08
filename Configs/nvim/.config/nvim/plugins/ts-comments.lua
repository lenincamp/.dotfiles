-- ts-comments.nvim: sets correct commentstring based on treesitter context.
-- Essential for JSX/TSX where {/* */} is needed inside JSX but // outside.

local ok, tsc = pcall(require, "ts-comments")
if not ok then return end

tsc.setup()
