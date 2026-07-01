--------------------------------------------------------------------------------
-- Filetypes
--------------------------------------------------------------------------------
local AVANTE_FTS = {
  Avante = true,
  AvanteInput = true,
  AvantePromptInput = true,
}

local INTRUSIVE_FTS = {
  markdown = true,
  gitcommit = true,
  NeogitCommitMessage = true,
}

local function is_avante(ft)
  return AVANTE_FTS[ft] ~= nil
end

local function is_intrusive(ft)
  return is_avante(ft) or INTRUSIVE_FTS[ft] ~= nil
end

local function completion_enabled()
  return not is_intrusive(vim.bo.filetype)
end

--------------------------------------------------------------------------------
-- Completion sources
--------------------------------------------------------------------------------
local COMPLETION_SOURCES = {
  "lsp",
  "minuet",
  "snippets",
  "path",
  "buffer",
}

require("blink.cmp").setup({
  -- Force the Rust fuzzy matcher: the dylib is built locally in
  -- blink.cmp/target/release, so no runtime binary download/replacement.
  -- Source priority is expressed via each provider's `score_offset` (below)
  -- instead of a custom Lua sort, which would silently drop sorting back to
  -- Lua and defeat the Rust matcher.
  fuzzy = {
    implementation = "rust",
    sorts = { "exact", "score", "sort_text" },
  },
  -- Signature help while typing function args (experimental)
  signature = { enabled = true },
  keymap = {
    preset = "default",
    ["<Tab>"] = {
      function(cmp)
        local ok_duet, duet = pcall(require, "minuet.duet")
        if ok_duet and duet.action and duet.action.is_visible and duet.action.is_visible() then
          cmp.hide()
          return duet.action.apply()
        end

        local ok_virtualtext, virtualtext = pcall(require, "minuet.virtualtext")
        if
          ok_virtualtext
          and virtualtext.action
          and virtualtext.action.is_visible
          and virtualtext.action.is_visible()
        then
          cmp.hide()
          return virtualtext.action.accept()
        end
      end,
      "snippet_forward",
      "fallback",
    },
  },
  completion = {
    keyword = {
      -- Keep full-token replacement so accepting a completion from mid-word
      -- replaces the whole symbol (desired editing behavior).
      range = "full",
    },
    list = {
      selection = {
        preselect = false,
        auto_insert = false,
      },
    },
    menu = {
      border = "rounded",
      auto_show = function()
        local ft = vim.bo.filetype
        return ft == "AvanteInput" or not is_intrusive(ft)
      end,
      draw = {
        treesitter = { "lsp" },
        -- Columns: icon + label + kind label aligned
        columns = {
          { "kind_icon", gap = 1 },
          { "label", "label_description", gap = 1 },
          { "kind" },
        },
        components = {
          kind = {
            text = function(ctx)
              return ctx.source_id == "minuet" and "Claude" or ctx.kind
            end,
          },
        },
      },
    },
    documentation = {
      -- Shown on demand via the default preset (<C-space>);
      -- scroll with <C-b>/<C-f>. Sized large so long AI suggestions
      -- (Minuet can emit full functions) stay fully readable.
      auto_show = false,
      window = {
        min_width = 30,
        max_width = math.floor(vim.o.columns * 0.5), -- 50% screen width
        max_height = math.floor(vim.o.lines * 0.6), -- 60% screen height
        border = "rounded",
        scrollbar = true,
      },
    },
    ghost_text = { enabled = false },
  },

  -- ── Appearance ────────────────────────────────────────────────────────────

  appearance = {
    nerd_font_variant = "normal",
    kind_icons = {
      -- ── Language constructs ───────────────────────────────────────────────
      Text = "󰦪", -- text lines              → plain text
      Keyword = "󰌋", -- hash #                  → reserved keyword
      Operator = "󰆕", -- ±                       → operator
      Snippet = "󰃃", -- scissors                → cut & insert

      -- ── Functions & methods ───────────────────────────────────────────────
      Function = "󰊕", -- lambda ƒ                → standalone function
      Method = "󰆧", -- cube outline            → method on object
      Constructor = "󰘎", -- hammer                  → creates an instance

      -- ── Variables & fields ────────────────────────────────────────────────
      Variable = "󰀫", -- greek alpha             → named variable
      Field = "󰜢", -- field marker            → struct/record field
      Property = "󰭹", -- dot chain               → obj.property accessor
      Constant = "󰐀", -- lock                    → immutable value

      -- ── Types & structures ────────────────────────────────────────────────
      Class = "󰠱", -- C in circle             → class definition
      Interface = "󰜰", -- brackets outline        → interface contract
      Struct = "󰙅", -- nested boxes            → struct layout
      Enum = "󰦨", -- numbered list           → enumeration
      EnumMember = "󰐉", -- radio button            → specific enum value
      TypeParameter = "󰊄", -- T marker                → generic <T>

      -- ── Modules & scope ───────────────────────────────────────────────────
      Module = "󰅩", -- package box             → module/namespace
      Unit = "󰑭", -- ruler                   → measurement unit
      Value = "󰎠", -- number                  → literal value

      -- ── References & navigation ───────────────────────────────────────────
      Reference = "󰌹", -- chain link              → cross-reference
      File = "󰈙", -- file                    → file path
      Folder = "󰉋", -- folder                  → directory

      -- ── Visual & runtime ──────────────────────────────────────────────────
      Color = "󰏘", -- color circle            → color value
      Event = "󱐋", -- lightning bolt          → event/trigger

      -- ── AI ────────────────────────────────────────────────────────────────
      Claude = "󰚩", -- robot                   → AI suggestion
      claude = "󰚩",
    },
  },

  -- ── Cmdline completion ────────────────────────────────────────────────────

  cmdline = {
    keymap = {
      preset = "cmdline",
      ["<Left>"] = false,
      ["<Right>"] = false,
    },
    -- Must be set explicitly: the top-level sources.default override below
    -- also replaces blink's built-in cmdline default ({ buffer, cmdline }),
    -- which otherwise leaves the real `cmdline` source disabled for `:`.
    sources = { default = { "buffer", "cmdline" } },
    completion = {
      list = { selection = { preselect = false } },
      menu = {
        auto_show = function()
          return vim.fn.getcmdtype() == ":"
        end,
      },
      ghost_text = { enabled = true },
    },
  },
  sources = {
    default = COMPLETION_SOURCES,
    per_filetype = {
      AvanteInput = { "avante" },
      mysql = { "snippets", "dadbod", "buffer" },
      plsql = { "snippets", "dadbod", "buffer" },
      sql = { "snippets", "dadbod", "buffer" },
      ["dap-repl"] = { inherit_defaults = true, "dap" },
      ["dapui_watches"] = { inherit_defaults = true, "dap" },
      ["dapui_hover"] = { inherit_defaults = true, "dap" },
    },
    providers = {
      -- Descending score_offset enforces source priority:
      -- lsp > minuet > snippets > dadbod > path > buffer.
      lsp = {
        score_offset = 100,
      },
      minuet = {
        name = "󰋦",
        module = "minuet.blink",
        score_offset = 80,
        async = true,
        timeout_ms = 2400,
        enabled = completion_enabled,
      },
      snippets = {
        score_offset = 60,
        min_keyword_length = 1,
      },
      dadbod = {
        name = "Dadbod",
        module = "vim_dadbod_completion.blink",
        score_offset = 40,
      },
      path = {
        score_offset = 20,
        enabled = function()
          return not is_avante(vim.bo.filetype)
        end,
      },
      buffer = {
        score_offset = 0,
        enabled = completion_enabled,
      },
      -- Undefined otherwise, which defaults to score_offset = 0 and ties
      -- with `buffer` in cmdline mode — real command/argument completions
      -- must outrank buffer words there.
      cmdline = {
        score_offset = 20,
      },
      avante = {
        name = "Avante",
        module = "blink-cmp-avante",
        score_offset = 1000,
      },
      dap = {
        name = "DAP",
        module = "blink-cmp-dap",
        score_offset = 1000,
      },
    },
  },
})
