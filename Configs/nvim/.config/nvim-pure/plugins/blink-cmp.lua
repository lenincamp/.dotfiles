require("blink.cmp").setup({
  fuzzy = { implementation = "prefer_rust" },

  -- Signature help while typing function args
  signature = { enabled = true },

  -- ── Keymaps ─────────────────────────────────────────────────────────────────
  keymap = {
    preset = "none",
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-e>"] = { "hide", "fallback" },
    ["<C-y>"] = { "select_and_accept", "fallback" },
    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
    ["<C-n>"] = { "select_next", "fallback_to_mappings" },
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
    ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
    ["<CR>"]  = { "accept", "fallback" },

    -- Documentation scroll (half page — easier for large Copilot suggestions)
    ['<C-u>'] = { 'scroll_signature_up', 'fallback' },
    ['<C-d>'] = { 'scroll_signature_down', 'fallback' },

    -- Toggle doc window visibility (see full suggestion or hide to focus)
    -- ["<M-d>"] = { "show_documentation", "hide_documentation" },
  },

  -- ── Completion behaviour ──────────────────────────────────────────────────

  completion = {
    accept = {
      auto_brackets = { enabled = true },
    },
    menu = {
      draw = {
        treesitter = { "lsp" },
        -- Columns: icon + label + kind label aligned
        columns = {
          { "kind_icon", gap = 1 },
          { "label",     "label_description", gap = 1 },
          { "kind" },
        },
      },
    },
    documentation = {
      auto_show          = true,
      auto_show_delay_ms = 200,
      -- ── Documentation window — optimised for long Copilot suggestions ──────
      -- Copilot can generate full functions (50-100+ lines).
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
    ghost_text = { enabled = true },
  },

  -- ── Appearance ────────────────────────────────────────────────────────────

  appearance = {
    use_nvim_cmp_as_default = true,
    nerd_font_variant       = "normal",
    kind_icons = {
      -- ── Language constructs ───────────────────────────────────────────────
      -- [CHANGED] document+pencil→ simpler T-with-lines for plain text
      Text          = "󰦪",   -- text lines              → plain text
      Keyword       = "󰌋",   -- hash #                  → reserved keyword
      Operator      = "󰆕",   -- ±                       → operator
      Snippet       = "󰃃",   -- scissors                → cut & insert

      -- ── Functions & methods ───────────────────────────────────────────────
      Function      = "󰊕",   -- lambda ƒ                → standalone function
      -- [CHANGED] function-variant→ cube = function enclosed in a class
      Method        = "󰆧",   -- cube outline            → method on object
      -- [CHANGED] cog (settings)→ hammer = builds/constructs an object
      Constructor   = "󰘎",   -- hammer                  → creates an instance

      -- ── Variables & fields ────────────────────────────────────────────────
      Variable      = "󰀫",   -- greek alpha             → named variable
      -- [CHANGED] checkbox (done)→ lspkind universal field icon
      Field         = "󰜢",   -- field marker            → struct/record field
      Property      = "󰭹",   -- dot chain               → obj.property accessor
      Constant      = "󰐀",   -- lock                    → immutable value

      -- ── Types & structures ────────────────────────────────────────────────
      Class         = "󰠱",   -- C in circle             → class definition
      Interface     = "󰜰",   -- brackets outline        → interface contract
      Struct        = "󰙅",   -- nested boxes            → struct layout
      Enum          = "󰦨",   -- numbered list           → enumeration
      -- [CHANGED] plus-circle (add)→ radio button = one option from a set
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
      Copilot       = "󰚩",   -- shooting star           → AI suggestion
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

  snippets = { preset = "mini_snippets" },

  -- ── Sources ───────────────────────────────────────────────────────────────

  sources = {
    default = { "lsp", "copilot", "path", "snippets", "buffer" },
    providers = {
      -- Copilot source via blink-copilot
      copilot = {
        name         = "copilot",
        module       = "blink-copilot",
        score_offset = 50,         -- below LSP but above path/buffer
        async        = true,
        opts = {
          max_completions = 3,
          -- kind_name must match the key in appearance.kind_icons below ("Copilot")
          kind_name   = "Copilot",
          -- Use the SAME icon as appearance.kind_icons.Copilot to avoid conflicts
          kind_icon   = "󰚩",
          -- Reduce debounce for faster suggestions (default is 200ms)
          debounce    = 75,
          auto_refresh = {
            -- Re-fetch when cursor moves within a word (faster feel)
            enabled = true,
          },
        },
      },
      -- Disable path completions inside copilot-chat buffers
      path = {
        enabled = function()
          return vim.bo.filetype ~= "copilot-chat"
        end,
      },
    },
  },
})
