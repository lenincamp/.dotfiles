local ok, rm = pcall(require, "render-markdown")
if not ok then return end

rm.setup({
  file_types = { "markdown", "Avante" },
  code = {
    sign      = false,
    width     = "block",
    right_pad = 1,
  },
  heading = {
    sign  = false,
    icons = {},
  },
  checkbox = { enabled = false },
  latex    = { enabled = false },
})

-- Toggle: <leader>uM (kept under UI group, avoids collision with tabline mode)
local ok_s, Snacks = pcall(require, "snacks")
if ok_s and Snacks.toggle then
  Snacks.toggle({
    name = "Render Markdown",
    get  = function() return require("render-markdown").get() end,
    set  = function(v) require("render-markdown").set(v) end,
  }):map("<leader>uM")
end
