-- nvim-treesitter-textobjects (main branch).
-- Replaces the hand-rolled modules/editor/treesitter_textobjects.lua.
-- Uses the language `textobjects.scm` queries instead of a hardcoded node table.

require("nvim-treesitter-textobjects").setup({
  select = {
    lookahead = true,
    include_surrounding_whitespace = false,
  },
  move = {
    set_jumps = true,
  },
})

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")
local swap = require("nvim-treesitter-textobjects.swap")

local function sel(query)
  return function()
    select.select_textobject(query, "textobjects")
  end
end

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- ── Select (operator-pending / visual) ──────────────────────────────────────
-- function / class / parameter (parity with previous keymaps, now outer/inner)
map({ "o", "x" }, "af", sel("@function.outer"), "Around function")
map({ "o", "x" }, "if", sel("@function.inner"), "Inside function")
map({ "o", "x" }, "ac", sel("@class.outer"), "Around class")
map({ "o", "x" }, "ic", sel("@class.inner"), "Inside class")
map({ "o", "x" }, "aa", sel("@parameter.outer"), "Around parameter")
map({ "o", "x" }, "ia", sel("@parameter.inner"), "Inside parameter")

-- new textobjects provided by the plugin (conflict-free keys)
map({ "o", "x" }, "al", sel("@loop.outer"), "Around loop")
map({ "o", "x" }, "il", sel("@loop.inner"), "Inside loop")
map({ "o", "x" }, "ai", sel("@conditional.outer"), "Around conditional")
map({ "o", "x" }, "ii", sel("@conditional.inner"), "Inside conditional")
map({ "o", "x" }, "a=", sel("@assignment.outer"), "Around assignment")
map({ "o", "x" }, "i=", sel("@assignment.inner"), "Inside assignment")
map({ "o", "x" }, "am", sel("@call.outer"), "Around call")
map({ "o", "x" }, "im", sel("@call.inner"), "Inside call")

-- ── Move (normal) ───────────────────────────────────────────────────────────
map("n", "]f", function() move.goto_next_start("@function.outer", "textobjects") end, "Next function start")
map("n", "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, "Prev function start")
map("n", "]F", function() move.goto_next_end("@function.outer", "textobjects") end, "Next function end")
map("n", "[F", function() move.goto_previous_end("@function.outer", "textobjects") end, "Prev function end")

map("n", "]c", function() move.goto_next_start("@class.outer", "textobjects") end, "Next class start")
map("n", "[c", function() move.goto_previous_start("@class.outer", "textobjects") end, "Prev class start")
map("n", "]C", function() move.goto_next_end("@class.outer", "textobjects") end, "Next class end")
map("n", "[C", function() move.goto_previous_end("@class.outer", "textobjects") end, "Prev class end")

map("n", "]a", function() move.goto_next_start("@parameter.inner", "textobjects") end, "Next parameter")
map("n", "[a", function() move.goto_previous_start("@parameter.inner", "textobjects") end, "Prev parameter")

-- new movement: loops
map("n", "]l", function() move.goto_next_start("@loop.outer", "textobjects") end, "Next loop start")
map("n", "[l", function() move.goto_previous_start("@loop.outer", "textobjects") end, "Prev loop start")
map("n", "]L", function() move.goto_next_end("@loop.outer", "textobjects") end, "Next loop end")
map("n", "[L", function() move.goto_previous_end("@loop.outer", "textobjects") end, "Prev loop end")

-- ── Swap (normal) ───────────────────────────────────────────────────────────
map("n", "gsn", function() swap.swap_next("@parameter.inner") end, "Swap param next")
map("n", "gsp", function() swap.swap_previous("@parameter.inner") end, "Swap param prev")
