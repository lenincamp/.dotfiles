local function avante_filetype(ft)
  return ft == "Avante" or ft == "AvanteInput" or ft == "AvantePromptInput"
end

local function text_like_filetype(ft)
  return avante_filetype(ft)
    or ft == "markdown"
    or ft == "gitcommit"
    or ft == "NeogitCommitMessage"
end

local function intrusive_context()
  return text_like_filetype(vim.bo.filetype)
end

local completion_sources = { "lsp", "minuet", "snippets", "path", "buffer" }
local completion_source_priority = {}

for index, source in ipairs(completion_sources) do
  completion_source_priority[source] = index
end

completion_source_priority.dadbod = completion_source_priority.snippets + 1

require("blink.cmp").setup({
  -- Force Rust fuzzy matcher and avoid runtime binary downloads/replacements.
  -- The dylib is built locally in blink.cmp/target/release and version-pinned.
  fuzzy = {
    implementation = "prefer_rust",
    sorts = {
      function(a, b)
        local priority_a = completion_source_priority[a.source_id] or math.huge
        local priority_b = completion_source_priority[b.source_id] or math.huge

        if priority_a ~= priority_b then
          return priority_a < priority_b
        end
      end,
      "score",
      "sort_text",
    },
  },

  -- Signature help while typing function args
  signature = { enabled = true },

  -- ── Keymaps ─────────────────────────────────────────────────────────────────
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
        if ok_virtualtext and virtualtext.action and virtualtext.action.is_visible and virtualtext.action.is_visible() then
          cmp.hide()
          return virtualtext.action.accept()
        end
      end,
      "snippet_forward",
      "fallback",
    },
  },

  -- ── Completion behaviour ──────────────────────────────────────────────────

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
    accept = {
      auto_brackets = { enabled = true },
    },
    menu = {
      auto_show = function()
        if vim.bo.filetype == "AvanteInput" then
          return true
        end
        return not intrusive_context()
      end,
      draw = {
        treesitter = { "lsp" },
        -- Columns: icon + label + kind label aligned
        columns = {
          { "kind_icon", gap = 1 },
          { "label",     "label_description", gap = 1 },
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
      auto_show          = false,
      auto_show_delay_ms = 200,
      -- ── Documentation window — optimised for long AI suggestions ────────────
      -- Minuet can generate full functions (50-100+ lines).
      -- Large window + scrollbar makes them fully readable.
      -- Navigation: <C-b> scroll down | <C-f> scroll up (see keymap section)
      window = {
        min_width        = 30,
        max_width        = math.floor(vim.o.columns * 0.5),  -- 50% screen width
        max_height       = math.floor(vim.o.lines   * 0.6),  -- 60% screen height
        desired_min_width  = 60,
        desired_min_height = 15,
        border           = "rounded",
        scrollbar        = true,   -- visual indicator when there's more content
        winblend         = 0,
        -- Show doc on the side that has more space
        direction_priority = {
          menu_north = { "e", "w", "n", "s" },
          menu_south = { "e", "w", "s", "n" },
        },
      },
    },
    ghost_text = { enabled = false },
  },

  -- ── Appearance ────────────────────────────────────────────────────────────

  appearance = {
    use_nvim_cmp_as_default = true,
    nerd_font_variant       = "normal",
    kind_icons = {
      -- ── Language constructs ───────────────────────────────────────────────
      Text          = "󰦪",   -- text lines              → plain text
      Keyword       = "󰌋",   -- hash #                  → reserved keyword
      Operator      = "󰆕",   -- ±                       → operator
      Snippet       = "󰃃",   -- scissors                → cut & insert

      -- ── Functions & methods ───────────────────────────────────────────────
      Function      = "󰊕",   -- lambda ƒ                → standalone function
      Method        = "󰆧",   -- cube outline            → method on object
      Constructor   = "󰘎",   -- hammer                  → creates an instance

      -- ── Variables & fields ────────────────────────────────────────────────
      Variable      = "󰀫",   -- greek alpha             → named variable
      Field         = "󰜢",   -- field marker            → struct/record field
      Property      = "󰭹",   -- dot chain               → obj.property accessor
      Constant      = "󰐀",   -- lock                    → immutable value

      -- ── Types & structures ────────────────────────────────────────────────
      Class         = "󰠱",   -- C in circle             → class definition
      Interface     = "󰜰",   -- brackets outline        → interface contract
      Struct        = "󰙅",   -- nested boxes            → struct layout
      Enum          = "󰦨",   -- numbered list           → enumeration
      EnumMember    = "󰐉",   -- radio button            → specific enum value
      TypeParameter = "󰊄",   -- T marker                → generic <T>

      -- ── Modules & scope ───────────────────────────────────────────────────
      Module        = "󰅩",   -- package box             → module/namespace
      Unit          = "󰑭",   -- ruler                   → measurement unit
      Value         = "󰎠",   -- number                  → literal value

      -- ── References & navigation ───────────────────────────────────────────
      Reference     = "󰌹",   -- chain link              → cross-reference
      File          = "󰈙",   -- file                    → file path
      Folder        = "󰉋",   -- folder                  → directory

      -- ── Visual & runtime ──────────────────────────────────────────────────
      Color         = "󰏘",   -- color circle            → color value
      Event         = "󱐋",   -- lightning bolt          → event/trigger

      -- ── AI ────────────────────────────────────────────────────────────────
      Claude        = "󰚩",   -- robot                   → AI suggestion
      claude        = "󰚩",
    },
  },

  -- ── Cmdline completion ────────────────────────────────────────────────────

  cmdline = {
    keymap = {
      preset = "cmdline",
      ["<Left>"]  = false,
      ["<Right>"] = false,
    },
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

  -- ── Snippet engine ────────────────────────────────────────────────────────

  snippets = { preset = "default" },

  -- ── Sources ───────────────────────────────────────────────────────────────

  sources = {
    default = completion_sources,
    per_filetype = {
      AvanteInput = { "avante" },
      mysql = { "snippets", "dadbod", "buffer" },
      plsql = { "snippets", "dadbod", "buffer" },
      sql = { "snippets", "dadbod", "buffer" },
    },
    providers = {
      lsp = {
        score_offset = 25,
      },
      dadbod = {
        name = "Dadbod",
        module = "vim_dadbod_completion.blink",
      },
      avante = {
        name = "Avante",
        module = "blink-cmp-avante",
        score_offset = 1000,
        opts = {},
      },
      minuet = {
        name         = "󰋦",
        module       = "minuet.blink",
        score_offset = 25,
        async        = true,
        timeout_ms   = 2400,
        enabled = function()
          return not intrusive_context()
        end,
      },
      -- Disable path completions inside Avante buffers
      path = {
        enabled = function()
          return not avante_filetype(vim.bo.filetype)
        end,
      },
      snippets = {
        min_keyword_length = 1,
        opts = {
          friendly_snippets = true,
          search_paths = { vim.fn.stdpath("config") .. "/snippets" },
        },
      },
      buffer = {
        enabled = function()
          return not intrusive_context()
        end,
      },
    },
  },
})
