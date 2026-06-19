local M = {}

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

local function env_if_set(env, name)
  if vim.env[name] then
    env[name] = vim.env[name]
  end
end

local function has_copilot_auth()
  local config_home = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")
  local auth_dir = config_home .. "/github-copilot"
  return vim.fn.filereadable(auth_dir .. "/hosts.json") == 1
    or vim.fn.filereadable(auth_dir .. "/apps.json") == 1
    or vim.fn.filereadable(vim.fn.stdpath("data") .. "/avante/github-copilot.json") == 1
end

local function has_avante_provider(name)
  return #vim.api.nvim_get_runtime_file("lua/avante/providers/" .. name .. ".lua", false) > 0
end

function M.context()
  load_claude_settings_env()

  local claude_api_key_name = "ANTHROPIC_API_KEY"
  if vim.fn.executable("llm-proxy-keys") == 1 then
    claude_api_key_name = "cmd:llm-proxy-keys -q -n"
  end

  local gemini_api_key = vim.env.AVANTE_GEMINI_API_KEY or vim.env.GEMINI_API_KEY
  local has_claude_code = vim.fn.executable("claude") == 1 and vim.fn.executable("claude-agent-acp") == 1
  local has_gemini_cli = vim.fn.executable("gemini") == 1 and gemini_api_key ~= nil

  local claude_code_env = {
    NODE_NO_WARNINGS = "1",
    HOME = vim.env.HOME,
    PATH = vim.env.PATH,
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

  local acp_providers = {}
  if has_claude_code then
    acp_providers["claude-code"] = {
      command = "claude-agent-acp",
      args = {},
      env = claude_code_env,
    }
  end

  if has_gemini_cli then
    acp_providers["gemini-cli"] = {
      command = "gemini",
      args = { "--experimental-acp" },
      env = {
        NODE_NO_WARNINGS = "1",
        GEMINI_API_KEY = gemini_api_key,
      },
      auth_method = "gemini-api-key",
    }
  end

  return {
    claude_api_key_name = claude_api_key_name,
    has_copilot_provider = has_avante_provider("copilot"),
    has_copilot_auth = has_copilot_auth(),
    has_claude_code = has_claude_code,
    has_gemini_cli = has_gemini_cli,
    acp_providers = acp_providers,
  }
end

function M.setup_options(state)
  return {
    provider = "claude",
    auto_suggestions_provider = nil,
    instructions_file = "avante.md",
    mode = "agentic",

    providers = {
      copilot = {
        hide_in_model_selector = not (state.has_copilot_provider and state.has_copilot_auth),
      },
      claude = {
        endpoint = vim.env.ANTHROPIC_BASE_URL or "https://api.anthropic.com",
        model = "claude-sonnet-4-6",
        api_key_name = state.claude_api_key_name,
        timeout = 60000,
        context_window = 200000,
        extra_request_body = {
          temperature = 0.2,
          max_tokens = 64000,
        },
      },
      ["claude-opus"] = {
        __inherited_from = "claude",
        endpoint = vim.env.ANTHROPIC_BASE_URL or "https://api.anthropic.com",
        model = "claude-opus-4-7",
        api_key_name = state.claude_api_key_name,
        timeout = 90000,
        extra_request_body = {
          temperature = 0.2,
          max_tokens = 32000,
        },
      },
      ["claude-haiku"] = {
        __inherited_from = "claude",
        endpoint = vim.env.ANTHROPIC_BASE_URL or "https://api.anthropic.com",
        model = "claude-haiku-4-5-20251001",
        api_key_name = state.claude_api_key_name,
        timeout = 30000,
        extra_request_body = {
          temperature = 0.1,
          max_tokens = 8192,
        },
      },
      gemini = {
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
        model = "gemini-2.5-pro-preview-05-06",
        timeout = 60000,
        context_window = 1048576,
        use_ReAct_prompt = true,
        extra_request_body = {
          generationConfig = {
            temperature = 0.2,
          },
        },
      },
    },

    acp_providers = state.acp_providers,
    input = { provider = "native" },
    selector = { provider = "native" },

    windows = {
      edit = { border = "rounded", start_insert = true },
      ask = { border = "rounded", start_insert = true, floating = true },
    },

    behaviour = {
      auto_suggestions = false,
      auto_set_keymaps = false,
      auto_approve_tool_permissions = false,
      auto_add_current_file = true,
      confirmation_ui_style = "inline_buttons",
      acp_follow_agent_locations = true,
    },

    suggestion = {
      debounce = 1200,
      throttle = 1200,
    },
  }
end

function M.provider_items(state)
  local items = {
    { name = "claude", label = "claude         │ claude-sonnet-4-6              (proxy→bedrock)" },
    { name = "claude-opus", label = "claude-opus    │ claude-opus-4-7                (proxy→bedrock)" },
    { name = "claude-haiku", label = "claude-haiku   │ claude-haiku-4-5               (proxy→bedrock)" },
    { name = "gemini", label = "gemini         │ gemini-2.5-pro-preview-05-06   (direct API)" },
  }

  if state.has_claude_code then
    table.insert(items, { name = "claude-code", label = "claude-code    │ ACP agent                      (terminal)" })
  end
  if state.has_gemini_cli then
    table.insert(items, { name = "gemini-cli", label = "gemini-cli     │ ACP agent                      (terminal)" })
  end

  return items
end

return M
