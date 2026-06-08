-- nvim-treesitter-textobjects: function/class navigation and text objects.
-- New API (main branch): configure via config.update() + manual keymaps.
-- Mirrors LazyVim: same keybindings, same queries.
--
-- Navigation   ]f/[f  function  ]c/[c  class  ]a/[a  parameter
-- Text objects  af/if  function  ac/ic  class  aa/ia  parameter
-- Swap          gsn/gsp  swap parameter with next/prev

local ok_cfg, cfg = pcall(require, "nvim-treesitter-textobjects.config")
if not ok_cfg then return end

local ok_move, move = pcall(require, "nvim-treesitter-textobjects.move")
local ok_sel,  sel  = pcall(require, "nvim-treesitter-textobjects.select")
local ok_swap, swap = pcall(require, "nvim-treesitter-textobjects.swap")

-- ── Global config ─────────────────────────────────────────────────────────────

cfg.update({
  move   = { set_jumps = true },        -- add to jumplist
  select = { lookahead = true },        -- jump ahead if cursor not on node
})

-- ── Navigation keymaps ────────────────────────────────────────────────────────

if ok_move then
  local map = vim.keymap.set

  -- ]f [f — function
  map("n", "]f", function() move.goto_next_start("@function.outer") end,     { desc = "Next function start" })
  map("n", "[f", function() move.goto_previous_start("@function.outer") end, { desc = "Prev function start" })
  map("n", "]F", function() move.goto_next_end("@function.outer") end,       { desc = "Next function end" })
  map("n", "[F", function() move.goto_previous_end("@function.outer") end,   { desc = "Prev function end" })

  -- ]c [c — class
  map("n", "]c", function() move.goto_next_start("@class.outer") end,        { desc = "Next class start" })
  map("n", "[c", function() move.goto_previous_start("@class.outer") end,    { desc = "Prev class start" })
  map("n", "]C", function() move.goto_next_end("@class.outer") end,          { desc = "Next class end" })
  map("n", "[C", function() move.goto_previous_end("@class.outer") end,      { desc = "Prev class end" })

  -- ]a [a — parameter / argument
  map("n", "]a", function() move.goto_next_start("@parameter.inner") end,    { desc = "Next parameter" })
  map("n", "[a", function() move.goto_previous_start("@parameter.inner") end, { desc = "Prev parameter" })
end

-- ── Text object keymaps (operator + visual modes) ────────────────────────────

if ok_sel then
  local map = function(keys, query, desc)
    for _, mode in ipairs({ "o", "x" }) do
      vim.keymap.set(mode, keys, function()
        sel.select_textobject(query)
      end, { desc = desc })
    end
  end

  map("af", "@function.outer", "Around function")
  map("if", "@function.inner", "Inside function")
  map("ac", "@class.outer",    "Around class")
  map("ic", "@class.inner",    "Inside class")
  map("aa", "@parameter.outer", "Around parameter")
  map("ia", "@parameter.inner", "Inside parameter")
end

-- ── Swap ──────────────────────────────────────────────────────────────────────

if ok_swap then
  vim.keymap.set("n", "gsn", function() swap.swap_next("@parameter.inner") end,
    { desc = "Swap param →" })
  vim.keymap.set("n", "gsp", function() swap.swap_previous("@parameter.inner") end,
    { desc = "Swap param ←" })
end
