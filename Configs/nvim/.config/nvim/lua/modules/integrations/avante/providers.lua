local M = {}

local claude_proxy = require("modules.ai.claude_proxy")

function M.setup_options()
  claude_proxy.ensure_env()

  local has_proxy = claude_proxy.has_proxy()
  local has_claude_code = claude_proxy.has_claude_code()
  local has_opencode = claude_proxy.has_opencode()

  -- Hide avante's built-in HTTP providers; gemini stays visible with a key.
  local providers = {
    claude = { hide_in_model_selector = true },
    copilot = { hide_in_model_selector = true },
    vertex = { hide_in_model_selector = true },
    vertex_claude = { hide_in_model_selector = true },
  }

  local default_provider
  if has_proxy then
    -- The LLM proxy is OpenAI-compatible (see the project's opencode.json:
    -- @ai-sdk/openai-compatible against /llm-proxy/v1). Talking to it with
    -- avante's native Anthropic `claude` provider sends thinking blocks the
    -- proxy can't round-trip ("thinking.signature: Field required"), so
    -- Claude is exposed here as OpenAI-compatible providers instead.
    local endpoint = claude_proxy.endpoint("openai")
    for _, key in ipairs(claude_proxy.MODEL_ORDER) do
      local m = claude_proxy.MODELS[key]
      providers[m.id] = {
        __inherited_from = "openai",
        endpoint = endpoint,
        api_key_name = claude_proxy.API_KEY_CMD,
        model = m.id,
        display_name = m.label,
        list_models = false, -- show only this curated model, not the full proxy catalog
        extra_request_body = { temperature = 0.2, max_tokens = 64000 },
      }
    end
    default_provider = claude_proxy.MODELS[claude_proxy.MODEL_ORDER[2]].id
  elseif has_opencode then
    default_provider = "opencode"
  elseif has_claude_code then
    default_provider = "claude-code"
  end

  -- avante spawns ACP agents with only PATH inherited, so any env the agent
  -- needs must be passed explicitly. On the work machine opencode reaches
  -- Claude via the LLM proxy key; on personal it falls back to its own auth.
  local acp_providers = {}
  if has_claude_code then
    acp_providers["claude-code"] = {
      command = "claude-agent-acp",
      args = {},
      env = claude_proxy.env_passthrough({
        NODE_NO_WARNINGS = "1",
        HOME = vim.env.HOME,
        PATH = vim.env.PATH,
        ACP_PATH_TO_CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude"),
      }),
    }
  end

  if has_opencode then
    local opencode_env = { HOME = vim.env.HOME }
    if has_proxy then
      opencode_env.ANTHROPIC_API_KEY = claude_proxy.api_key()
    end
    if vim.env.OPENCODE_API_KEY then
      opencode_env.OPENCODE_API_KEY = vim.env.OPENCODE_API_KEY
    end
    acp_providers["opencode"] = {
      command = "opencode",
      args = { "acp" },
      env = opencode_env,
    }
  end

  return {
    provider = default_provider,
    providers = providers,
    acp_providers = acp_providers,

    windows = {
      ask = { floating = true },
    },

    behaviour = {
      auto_set_keymaps = false,
      auto_approve_tool_permissions = false,
    },
  }
end

return M
