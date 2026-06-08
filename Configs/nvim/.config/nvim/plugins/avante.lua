-- avante.nvim: chat/agent UI
-- Providers: copilot (default, enterprise), claude (proxy-llm→bedrock), gemini (direct API)
-- ACP agents: claude-code (terminal), gemini-cli

local ok, avante = pcall(require, "avante")
if not ok then return end

-- ── Availability ──────────────────────────────────────────────────────────

-- Inherit Claude Code's env block (~/.claude/settings.json `env`) when those
-- vars aren't already exported by the shell. Claude Code only injects them
-- into its own subprocesses, so a regular `nvim` from a terminal won't see
-- them — without this, avante falls back to api.anthropic.com and fails with
-- "invalid x-api-key" against the proxy key.
local function load_claude_settings_env()
  local path = vim.fn.expand("~/.claude/settings.json")
  if vim.fn.filereadable(path) == 0 then return end
  local content = table.concat(vim.fn.readfile(path), "\n")
  local ok_json, parsed = pcall(vim.json.decode, content)
  if not ok_json or type(parsed) ~= "table" or type(parsed.env) ~= "table" then return end
  for name, value in pairs(parsed.env) do
    if vim.env[name] == nil and type(value) == "string" then
      vim.env[name] = value
    end
  end
end
load_claude_settings_env()

-- Claude key: use llm-proxy-keys helper if available, else env var.
-- Avante's "cmd:" syntax runs the helper at request time and uses stdout line 1.
-- Flags: -q (quiet, key-only stdout), -n (cache-only, no browser auth blocking).
local claude_api_key_name = "ANTHROPIC_API_KEY"
if vim.fn.executable("llm-proxy-keys") == 1 then
  claude_api_key_name = "cmd:llm-proxy-keys -q -n"
end

local gemini_api_key = vim.env.AVANTE_GEMINI_API_KEY or vim.env.GEMINI_API_KEY

local has_claude_code = vim.fn.executable("claude") == 1
  and vim.fn.executable("claude-agent-acp") == 1

local has_gemini_cli = vim.fn.executable("gemini") == 1
  and gemini_api_key ~= nil

-- ── Claude ACP env (proxy-llm + bedrock; forward CA bundle for internal TLS) ──

local function env_if_set(env, name)
  if vim.env[name] then env[name] = vim.env[name] end
end

local claude_code_env = {
  NODE_NO_WARNINGS = "1",
  HOME             = vim.env.HOME,
  PATH             = vim.env.PATH,
  ACP_PATH_TO_CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude"),
}

for _, name in ipairs({
  "ACP_PERMISSION_MODE",
  "ANTHROPIC_API_KEY",
  "ANTHROPIC_BASE_URL",
  "ANTHROPIC_AWS_BASE_URL",
  "ANTHROPIC_BEDROCK_BASE_URL",
  "ANTHROPIC_VERTEX_BASE_URL",
  "API_TIMEOUT_MS",
  "AWS_ACCESS_KEY_ID",
  "AWS_CA_BUNDLE",
  "AWS_DEFAULT_REGION",
  "AWS_PROFILE",
  "AWS_REGION",
  "AWS_SECRET_ACCESS_KEY",
  "AWS_SESSION_TOKEN",
  "CLAUDE_CODE_OAUTH_TOKEN",
  "CLAUDE_CONFIG_DIR",
  "CLAUDE_CODE_USE_BEDROCK",
  "CLAUDE_CODE_USE_FOUNDRY",
  "CLAUDE_CODE_USE_VERTEX",
  "DISABLE_ERROR_REPORTING",
  "DISABLE_TELEMETRY",
  "HTTP_PROXY",
  "HTTPS_PROXY",
  "NO_PROXY",
  "NODE_EXTRA_CA_CERTS",
  "SSL_CERT_FILE",
  "http_proxy",
  "https_proxy",
  "no_proxy",
}) do
  env_if_set(claude_code_env, name)
end

-- ── ACP providers (conditional on binary availability) ────────────────────

local acp_providers = {}

if has_claude_code then
  acp_providers["claude-code"] = {
    command = "claude-agent-acp",
    args    = {},
    env     = claude_code_env,
  }
end

if has_gemini_cli then
  acp_providers["gemini-cli"] = {
    command     = "gemini",
    args        = { "--experimental-acp" },
    env         = {
      NODE_NO_WARNINGS = "1",
      GEMINI_API_KEY   = gemini_api_key,
    },
    auth_method = "gemini-api-key",
  }
end

-- ── Setup ─────────────────────────────────────────────────────────────────

avante.setup({
  -- Copilot is default: enterprise plan, authenticated via copilot.lua
  -- Inline suggestions handled by blink-cmp + blink-copilot (not avante)
  provider                  = "copilot",
  auto_suggestions_provider = nil,
  instructions_file         = "avante.md",
  mode                      = "agentic",

  providers = {

    -- ── Copilot enterprise ────────────────────────────────────────────────
    -- Switch models via <leader>a? (AvanteModels) to see available enterprise models
    copilot = {
      endpoint       = "https://api.githubcopilot.com",
      -- gpt-5.x and *-codex are gated to VSCode/Codex integrations; avante's
      -- vscode-chat integration ID can only use chat-completions models.
      -- gpt-4.1 is unlimited on enterprise and the strongest chat-accessible model.
      model          = "gpt-4.1-2025-04-14",
      timeout        = 30000,
      context_window = 64000,
      extra_request_body = {
        max_tokens = 20480,
      },
    },

    -- ── Claude via proxy-llm → Bedrock ────────────────────────────────────
    -- ANTHROPIC_BASE_URL = internal proxy (LiteLLM → Bedrock)
    -- api_key_name = "cmd:..." → avante runs llm-proxy-keys at request time;
    --   stdout line 1 is sent as x-api-key header.
    claude = {
      endpoint       = vim.env.ANTHROPIC_BASE_URL or "https://api.anthropic.com",
      model          = "claude-sonnet-4-6",
      api_key_name   = claude_api_key_name,
      timeout        = 60000,
      context_window = 200000,
      extra_request_body = {
        temperature = 0.2,
        max_tokens  = 64000,
      },
    },

    -- ── Claude Opus (most capable, same proxy) ────────────────────────────
    ["claude-opus"] = {
      __inherited_from = "claude",
      endpoint     = vim.env.ANTHROPIC_BASE_URL or "https://api.anthropic.com",
      model        = "claude-opus-4-7",
      api_key_name = claude_api_key_name,
      timeout      = 90000,
      extra_request_body = {
        temperature = 0.2,
        max_tokens  = 32000,
      },
    },

    -- ── Claude Haiku (fast, same proxy) ───────────────────────────────────
    -- Set endpoint + api_key_name explicitly: __inherited_from resolves lazily
    -- and some avante code paths read these fields directly.
    ["claude-haiku"] = {
      __inherited_from = "claude",
      endpoint     = vim.env.ANTHROPIC_BASE_URL or "https://api.anthropic.com",
      model        = "claude-haiku-4-5-20251001",
      api_key_name = claude_api_key_name,
      timeout      = 30000,
      extra_request_body = {
        temperature = 0.1,
        max_tokens  = 8192,
      },
    },

    -- ── Gemini direct API ─────────────────────────────────────────────────
    -- Requires GEMINI_API_KEY or AVANTE_GEMINI_API_KEY
    -- Switch models via <leader>a? if newer versions are available
    gemini = {
      endpoint         = "https://generativelanguage.googleapis.com/v1beta/models",
      model            = "gemini-2.5-pro-preview-05-06",
      timeout          = 60000,
      context_window   = 1048576,
      use_ReAct_prompt = true,
      extra_request_body = {
        generationConfig = {
          temperature = 0.2,
        },
      },
    },
  },

  acp_providers = acp_providers,

  input    = { provider = "snacks" },
  selector = { provider = "snacks" },

  -- Rounded borders make floating windows legible on transparent themes
  -- (default avante uses whitespace borders that disappear when bg is clear).
  windows = {
    edit = { border = "rounded", start_insert = true },
    ask  = { border = "rounded", start_insert = true, floating = true },
  },

  behaviour = {
    auto_suggestions              = false,  -- blink-cmp + blink-copilot handles inline
    auto_set_keymaps              = false,
    auto_approve_tool_permissions = false,
    auto_add_current_file         = true,
    confirmation_ui_style         = "inline_buttons",
    acp_follow_agent_locations    = true,
  },

  suggestion = {
    debounce = 1200,
    throttle = 1200,
  },
})

-- ── Keymaps ───────────────────────────────────────────────────────────────

local map = vim.keymap.set

local function avante_sidebar()
  local sidebar = require("avante").get()
  if sidebar:is_open() then return sidebar end

  require("avante.api").ask()
  return require("avante").get()
end

local function add_file_to_avante(filepath)
  if not filepath or filepath == "" then return end

  local ok_utils, utils = pcall(require, "avante.utils")
  if not ok_utils then return end

  avante_sidebar().file_selector:add_selected_file(utils.relative_path(filepath))
end

local function add_current_buffer_to_avante()
  add_file_to_avante(vim.api.nvim_buf_get_name(0))
end

local function add_open_buffers_to_avante()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted then
      add_file_to_avante(vim.api.nvim_buf_get_name(bufnr))
    end
  end
end

map({ "n", "x" }, "<leader>aa", function()
  require("avante.api").ask()
end, { desc = "Avante: ask" })

map("n", "<leader>at", function()
  require("avante").toggle()
end, { desc = "Avante: toggle" })

map({ "n", "x" }, "<leader>ae", function()
  require("avante.api").edit()
end, { desc = "Avante: edit" })

map("n", "<leader>an", "<cmd>AvanteChatNew<CR>",       { desc = "Avante: new chat" })
map("n", "<leader>ah", "<cmd>AvanteHistory<CR>",       { desc = "Avante: history" })
map("n", "<leader>aS", "<cmd>AvanteStop<CR>",          { desc = "Avante: stop" })
map("n", "<leader>ar", "<cmd>AvanteRefresh<CR>",       { desc = "Avante: refresh" })
map("n", "<leader>af", "<cmd>AvanteFocus<CR>",         { desc = "Avante: focus" })
-- All configured providers + static models in one picker.
-- AvanteModels only queries the active provider's API (Copilot-only dynamic list).
local function pick_provider()
  local ok_cfg, cfg = pcall(require, "avante.config")
  local current = (ok_cfg and cfg.provider) or "?"

  local items = {
    { name = "copilot",      label = "copilot        │ gpt-4.1                        (enterprise, unlimited)" },
    { name = "claude",       label = "claude         │ claude-sonnet-4-6              (proxy→bedrock)" },
    { name = "claude-opus",  label = "claude-opus    │ claude-opus-4-7                (proxy→bedrock)" },
    { name = "claude-haiku", label = "claude-haiku   │ claude-haiku-4-5               (proxy→bedrock)" },
    { name = "gemini",       label = "gemini         │ gemini-2.5-pro-preview-05-06   (direct API)" },
  }
  if has_claude_code then
    table.insert(items, { name = "claude-code", label = "claude-code    │ ACP agent                      (terminal)" })
  end
  if has_gemini_cli then
    table.insert(items, { name = "gemini-cli",  label = "gemini-cli     │ ACP agent                      (terminal)" })
  end

  vim.ui.select(items, {
    prompt      = "Avante provider  (active: " .. current .. ")",
    format_item = function(item) return item.label end,
  }, function(choice)
    if choice then require("avante.api").switch_provider(choice.name) end
  end)
end

map("n", "<leader>a?", pick_provider,                  { desc = "Avante: pick provider/model" })
map("n", "<leader>aM", "<cmd>AvanteModels<CR>",         { desc = "Avante: copilot models (dynamic)" })
map("n", "<leader>aP", "<cmd>AvanteSwitchProvider<CR>", { desc = "Avante: provider" })
map("n", "<leader>aC", "<cmd>AvanteClear<CR>",         { desc = "Avante: clear" })
map("n", "<leader>aR", "<cmd>AvanteShowRepoMap<CR>",   { desc = "Avante: repo map" })
map("n", "<leader>ac", add_current_buffer_to_avante,   { desc = "Avante: add current file" })
map("n", "<leader>aB", add_open_buffers_to_avante,     { desc = "Avante: add open buffers" })

map("n", "<leader>az", function()
  require("avante.api").zen_mode()
end, { desc = "Avante: zen mode" })
