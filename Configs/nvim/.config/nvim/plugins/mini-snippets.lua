-- mini.snippets: snippet engine with friendly-snippets language packs.
-- Integrates with blink.cmp via the "mini_snippets" preset (set in blink-cmp.lua).
-- Expand: type trigger word → blink popup → <C-n> to accept and expand.
-- Jump:   <C-l> forward  /  <C-h> backward  (inside an active snippet session).

local ok, ms = pcall(require, "mini.snippets")
if not ok then return end

local snippets_dir = vim.fn.stdpath("config") .. "/snippets"

-- Custom loader for Salesforce/Apex snippets (apex, html=lwc, javascript, xml)
local function sf_loader(ctx)
  local map = {
    apex       = "salesforce/apex.json",
    html       = "salesforce/lwc-html.json",
    javascript = "salesforce/lwc-js.json",
    xml        = "salesforce/lwc-xml.json",
  }
  local file = map[ctx.lang]
  if not file then return {} end
  local path = snippets_dir .. "/" .. file
  if vim.fn.filereadable(path) == 0 then return {} end
  return ms.gen_loader.from_file(path)(ctx)
end

-- Custom loader for per-language snippets in snippets/{lang}.json
local function lang_loader(ctx)
  local path = snippets_dir .. "/" .. ctx.lang .. ".json"
  if vim.fn.filereadable(path) == 0 then return {} end
  return ms.gen_loader.from_file(path)(ctx)
end

ms.setup({
  snippets = {
    ms.gen_loader.from_lang(),  -- friendly-snippets for all languages
    lang_loader,                -- per-lang custom: snippets/{lang}.json
    sf_loader,                  -- Salesforce/Apex/LWC custom snippets
  },

  -- Default <C-c> stops the session; keep <Esc> for normal-mode access mid-session.
  -- Uncomment to stop on <Esc> instead:
  -- mappings = { stop = "<Esc>" },

  expand = {
    -- Wrap the default select to cancel blink completion before showing vim.ui.select
    select = function(snippets, insert)
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then blink.cancel() end
      vim.schedule(function()
        MiniSnippets.default_select(snippets, insert)
      end)
    end,
  },
})
