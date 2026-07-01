local ignored_filetypes = {
  Avante = true,
  markdown = true,
  gitcommit = true,
  NeogitCommitMessage = true,
}

local claude_proxy = require("modules.ai.claude_proxy")
claude_proxy.ensure_env()

local ok, minuet = pcall(require, "minuet")
if not ok then
  return
end

local defaults = require("minuet.config")

-- =========================================================
-- System prompt patch
-- =========================================================
local system = vim.deepcopy(defaults.default_system_prefix_first)
system.guidelines = system.guidelines
  .. "\n8. Stop before text already present after `<cursorPosition>`; do not emit closing delimiters, quotes, or semicolons that already follow the cursor."

-- =========================================================
-- Core config
-- =========================================================
minuet.setup({
  provider = "claude",

  notify = "error",
  request_timeout = 3.2,
  throttle = 250,
  debounce = 120,

  context_window = 8000,
  context_ratio = 0.85,

  after_cursor_filter_length = 1,
  add_single_line_entry = false,
  n_completions = 3,

  curl_extra_args = { "--http1.1" },

  virtualtext = {
    auto_trigger_ft = { "*" },
    keymap = {
      accept_line = "<A-a>",
      accept_n_lines = "<A-z>",
      prev = "<A-[>",
      next = "<A-]>",
      dismiss = "<A-e>",
    },
  },

  enable_predicates = {
    function()
      return not (
        ignored_filetypes[vim.bo.filetype]
        or vim.bo.buftype ~= ""
      )
    end,
  },

  provider_options = {
    claude = {
      name = "Claude",
      model = claude_proxy.MODELS.HAIKU_4_5.id,
      api_key = claude_proxy.api_key,
      end_point = claude_proxy.endpoint("messages"),
      system = system,
      chat_input = defaults.default_chat_input_prefix_first,
      few_shots = defaults.default_few_shots_prefix_first,
      max_tokens = 128,
      stream = false,
      optional = {
        temperature = 0,
      },
    },
  },

  duet = {
    provider = "claude",
    request_timeout = 20,

    provider_options = {
      claude = {
        model = claude_proxy.MODELS.SONNET_4_6.id,

              api_key = claude_proxy.api_key,
        end_point = claude_proxy.endpoint("messages"),

        max_tokens = 8192,

        optional = {
          temperature = 0.1,
        },
      },
    },
  },
})

vim.keymap.set("n", "<leader>amp", "<cmd>Minuet duet predict<CR>", { desc = "Minuet: NES predict" })
vim.keymap.set("n", "<leader>ama", "<cmd>Minuet duet apply<CR>", { desc = "Minuet: NES apply" })
vim.keymap.set("n", "<leader>amd", "<cmd>Minuet duet dismiss<CR>", { desc = "Minuet: NES dismiss" })
