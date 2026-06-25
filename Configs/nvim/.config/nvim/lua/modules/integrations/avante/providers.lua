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

local function has_bedrock_env()
  return vim.env.BEDROCK_KEYS ~= nil
    or vim.env.AWS_PROFILE ~= nil
    or vim.env.AWS_REGION ~= nil
    or vim.env.AWS_DEFAULT_REGION ~= nil
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
    claude_model = vim.env.AVANTE_CLAUDE_MODEL or "claude-sonnet-4-6",
    has_bedrock = has_avante_provider("bedrock") and has_bedrock_env(),
    bedrock_model = vim.env.AVANTE_BEDROCK_MODEL or "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
    aws_region = vim.env.AWS_REGION or vim.env.AWS_DEFAULT_REGION,
    aws_profile = vim.env.AWS_PROFILE,
    has_copilot_provider = has_avante_provider("copilot"),
    has_copilot_auth = has_copilot_auth(),
    enable_copilot = vim.env.AVANTE_ENABLE_COPILOT == "1",
    has_claude_code = has_claude_code,
    has_gemini_cli = has_gemini_cli,
    acp_providers = acp_providers,
  }
end

function M.setup_options(state)
  local opts = {
    providers = {
      copilot = {
        hide_in_model_selector = not (state.has_copilot_provider and state.has_copilot_auth and state.enable_copilot),
      },
      claude = {
        endpoint = vim.env.ANTHROPIC_BASE_URL or "https://api.anthropic.com",
        model = state.claude_model,
        api_key_name = state.claude_api_key_name,
        timeout = 60000,
        context_window = 200000,
        extra_request_body = {
          temperature = 0.2,
          max_tokens = 64000,
        },
      },
    },

    acp_providers = state.acp_providers,

    windows = {
      ask = { floating = true },
    },

    behaviour = {
      auto_set_keymaps = false,
      auto_approve_tool_permissions = false,
    },
  }

  if state.has_bedrock then
    opts.providers.bedrock = {
      model = state.bedrock_model,
      aws_region = state.aws_region,
      aws_profile = state.aws_profile,
    }
  end

  return opts
end

function M.provider_items(state)
  local items = {
    { name = "claude", label = "claude       │ API/proxy                      " .. state.claude_model },
  }

  if state.has_bedrock then
    table.insert(items, { name = "bedrock", label = "bedrock      │ AWS Bedrock                    " .. state.bedrock_model })
  end
  if state.has_claude_code then
    table.insert(items, { name = "claude-code", label = "claude-code    │ ACP agent                      (terminal)" })
  end
  if state.has_gemini_cli then
    table.insert(items, { name = "gemini-cli", label = "gemini-cli     │ ACP agent                      (terminal)" })
  end

  return items
end

function M.model_items()
  local ok_cfg, Config = pcall(require, "avante.config")
  local ok_prov, Providers = pcall(require, "avante.providers")
  if not ok_cfg or not ok_prov then
    return {}
  end

  local items = {}
  local seen = {}

  for provider_name in pairs(Config.providers or {}) do
    local provider_cfg = Providers[provider_name]
    if provider_cfg and not provider_cfg.hide_in_model_selector and provider_cfg.is_env_set() then
      local model = provider_cfg.model
      local key = provider_name .. "|" .. (model or "")
      if model and not seen[key] then
        seen[key] = true
        items[#items + 1] = {
          provider_name = provider_name,
          model = model,
          label = string.format("%-18s %s", provider_name, model),
        }
      end
    end
  end

  table.sort(items, function(a, b)
    return a.label < b.label
  end)
  return items
end

function M.apply_model_choice(choice)
  local ok_cfg, Config = pcall(require, "avante.config")
  local ok_prov, Providers = pcall(require, "avante.providers")
  local ok_utils, Utils = pcall(require, "avante.utils")
  if not ok_cfg or not ok_prov or not choice then
    return
  end

  if choice.provider_name ~= Config.provider then
    Providers.refresh(choice.provider_name)
  end

  Config.override({
    providers = {
      [choice.provider_name] = vim.tbl_deep_extend(
        "force",
        Config.get_provider_config(choice.provider_name),
        { model = choice.model }
      ),
    },
  })

  local provider_cfg = Providers[choice.provider_name]
  if provider_cfg then
    provider_cfg.model = choice.model
  end

  if Config.windows.sidebar_header.include_model then
    local sidebar = require("avante").get()
    if sidebar and sidebar:is_open() then
      sidebar:render_result()
    end
  elseif ok_utils then
    Utils.info("Switched to model: " .. choice.label)
  end

  Config.save_last_model(choice.model, choice.provider_name)
end

function M.pick_model(_state)
  local items = M.model_items()
  if #items == 0 then
    vim.notify("No Avante models available", vim.log.levels.WARN)
    return
  end

  local ok_cfg, Config = pcall(require, "avante.config")
  local current = ok_cfg and Config.provider or "?"

  require("picker").select_items(items, {
    prompt = "Avante model  (provider: " .. current .. ")",
    scope = "global",
    search_threshold = 0,
    input_mode = true,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      M.apply_model_choice(choice)
    end
  end)
end

return M
