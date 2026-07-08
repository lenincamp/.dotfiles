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
-- Environment detection (mirrors avante/providers.lua)
-- =========================================================
local has_proxy = claude_proxy.has_proxy()
local has_opencode_key = vim.env.OPENCODE_GO_API_KEY ~= nil and vim.env.OPENCODE_GO_API_KEY ~= ""

if not has_proxy and not has_opencode_key then
  return
end

local active_provider = has_proxy and "claude" or "openai_compatible"

local provider_options
if has_proxy then
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
  }
else
  provider_options = {
    openai_compatible = {
      name = "OpenCode",
      model = "deepseek-v4-flash",
      end_point = "https://opencode.ai/zen/go/v1/chat/completions",
      api_key = vim.env.OPENCODE_GO_API_KEY or "",
      system = system,
      chat_input = defaults.default_chat_input_prefix_first,
      few_shots = defaults.default_few_shots_prefix_first,
      max_tokens = 128,
      stream = false,
      optional = {
        temperature = 0,
      },
    },
  }
end

local duet_options
if has_proxy then
  duet_options = {
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
  }
else
  duet_options = {
    provider = "openai_compatible",
    request_timeout = 20,
    provider_options = {
      openai_compatible = {
        model = "deepseek-v4-flash",
        end_point = "https://opencode.ai/zen/go/v1/chat/completions",
        api_key = vim.env.OPENCODE_GO_API_KEY or "",
        max_tokens = 8192,
        optional = {
          temperature = 0.1,
        },
      },
    },
  }
end

-- =========================================================
-- Core config
-- =========================================================
minuet.setup({
  provider = active_provider,

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

  provider_options = provider_options,

  duet = duet_options,
})

vim.keymap.set("n", "<leader>amp", "<cmd>Minuet duet predict<CR>", { desc = "Minuet: NES predict" })
vim.keymap.set("n", "<leader>ama", "<cmd>Minuet duet apply<CR>", { desc = "Minuet: NES apply" })
vim.keymap.set("n", "<leader>amd", "<cmd>Minuet duet dismiss<CR>", { desc = "Minuet: NES dismiss" })
