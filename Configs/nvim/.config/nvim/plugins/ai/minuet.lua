local ignored_filetypes = {
  Avante = true,
  markdown = true,
  gitcommit = true,
  NeogitCommitMessage = true,
}

local function ignored_context()
  local ft = vim.bo.filetype
  return ignored_filetypes[ft] == true
    or vim.bo.buftype ~= ""
end

local function load_claude_settings_env()
  local path = vim.fn.expand("~/.claude/settings.json")
  if vim.fn.filereadable(path) == 0 then
    return
  end

  local content = table.concat(vim.fn.readfile(path), "\n")
  local ok_json, parsed = pcall(vim.json.decode, content)
  if not ok_json or type(parsed) ~= "table" or type(parsed.env) ~= "table" then
    return
  end

  for name, value in pairs(parsed.env) do
    if vim.env[name] == nil and type(value) == "string" then
      vim.env[name] = value
    end
  end
end

local function llm_proxy_api_key()
  local key
  local warned = false

  return function()
    if key then
      return key
    end

    key = vim.trim(vim.fn.system({ "llm-proxy-keys", "-q", "-n" }) or "")
    if vim.v.shell_error == 0 and key ~= "" then
      return key
    end

    key = nil
    if not warned then
      warned = true
      vim.schedule(function()
        vim.notify("Minuet: llm-proxy-keys did not return an API key", vim.log.levels.WARN)
      end)
    end
    return vim.env.ANTHROPIC_API_KEY or ""
  end
end

local function claude_api_key()
  if vim.fn.executable("llm-proxy-keys") == 1 then
    return llm_proxy_api_key()
  end

  return "ANTHROPIC_API_KEY"
end

local function claude_messages_endpoint()
  local endpoint = vim.env.ANTHROPIC_BASE_URL
  if not endpoint or endpoint == "" then
    return "https://api.anthropic.com/v1/messages"
  end

  endpoint = endpoint:gsub("/+$", "")
  if endpoint:match("/v1/messages$") then
    return endpoint
  end
  if endpoint:match("/v1$") then
    return endpoint .. "/messages"
  end
  return endpoint .. "/v1/messages"
end

load_claude_settings_env()

local ok_minuet, minuet = pcall(require, "minuet")
if not ok_minuet then
  return
end

local minuet_defaults = require("minuet.config")
local completion_system = vim.deepcopy(minuet_defaults.default_system_prefix_first)
local api_key = claude_api_key()
local anthropic_endpoint = claude_messages_endpoint()

completion_system.guidelines = completion_system.guidelines
  .. "\n8. Stop before text already present after `<cursorPosition>`; do not emit closing delimiters, quotes, or semicolons that already follow the cursor."

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
      return not ignored_context()
    end,
  },

  provider_options = {
    claude = {
      name = "Claude",
      model = "claude-haiku-4-5-20251001",
      api_key = api_key,
      end_point = anthropic_endpoint,
      system = completion_system,
      chat_input = minuet_defaults.default_chat_input_prefix_first,
      few_shots = minuet_defaults.default_few_shots_prefix_first,
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
        model = "claude-sonnet-4-6",
        api_key = api_key,
        end_point = anthropic_endpoint,
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
