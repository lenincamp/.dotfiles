-- Single source of truth for talking to Claude through the internal
-- llm-proxy: model catalog, API key resolution, endpoint resolution and
-- ~/.claude/settings.json env loading. Consumed by avante and minuet so
-- both stay in sync instead of drifting.
local M = {}

M.API_KEY_CMD = "cmd:llm-proxy-keys -q -n"

M.MODELS = {
  OPUS_4_6     = { id = "anthropic.claude-opus-4-6",   label = "opus 4.6" },
  SONNET_4_6   = { id = "anthropic.claude-sonnet-4-6", label = "sonnet 4.6" },
  OPUS_4_8     = { id = "anthropic.claude-opus-4-8",   label = "opus 4.8" },
  SONNET_5     = { id = "anthropic.claude-sonnet-5",   label = "sonnet 5" },
  HAIKU_4_5    = { id = "anthropic.claude-haiku-4-5",  label = "haiku 4.5" },
  GPT_OSS_120B = { id = "openai.gpt-oss-120b",         label = "gpt-oss-120b" },
  GPT_5        = { id = "gpt-5",                       label = "gpt-5" },
  GPT_5_MINI   = { id = "gpt-5-mini",                  label = "gpt-5-mini" },
}

M.MODEL_ORDER = {
  "OPUS_4_6", "SONNET_4_6", "OPUS_4_8", "SONNET_5", "HAIKU_4_5",
  "GPT_OSS_120B", "GPT_5", "GPT_5_MINI",
}

local PASSTHROUGH_ENV_NAMES = {
  "ACP_PERMISSION_MODE",
  "ANTHROPIC_API_KEY",
  "ANTHROPIC_BASE_URL",
  "API_TIMEOUT_MS",
  "CLAUDE_CODE_OAUTH_TOKEN",
  "DISABLE_ERROR_REPORTING",
  "DISABLE_TELEMETRY",
}

local executable_cache = {}

local function is_executable(name)
  if executable_cache[name] == nil then
    executable_cache[name] = vim.fn.executable(name) == 1
  end
  return executable_cache[name]
end

function M.has_proxy()
  return is_executable("llm-proxy-keys")
end

function M.has_claude_code()
  return is_executable("claude") and is_executable("claude-agent-acp")
end

function M.has_opencode()
  return is_executable("opencode")
end

local env_loaded = false

-- Merges ~/.claude/settings.json's `env` table into vim.env, without
-- overwriting anything already set. Safe to call from multiple plugins.
function M.ensure_env()
  if env_loaded then
    return
  end
  env_loaded = true

  local path = vim.fs.normalize("~/.claude/settings.json")
  if vim.fn.filereadable(path) == 0 then
    return
  end

  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if not ok or type(data) ~= "table" or type(data.env) ~= "table" then
    return
  end

  for k, v in pairs(data.env) do
    if type(v) == "string" and vim.env[k] == nil then
      vim.env[k] = v
    end
  end
end

-- Copies whitelisted Claude/ACP env vars from vim.env into `dest`.
-- Defaults to the module's own allowlist; pass `names` to override it.
function M.env_passthrough(dest, names)
  for _, name in ipairs(names or PASSTHROUGH_ENV_NAMES) do
    if vim.env[name] then
      dest[name] = vim.env[name]
    end
  end
  return dest
end

local api_key_cache = nil
local warned_missing_key = false

-- Resolves the real API key string (llm-proxy-keys, falling back to
-- ANTHROPIC_API_KEY). Result is cached for the session.
function M.api_key()
  if api_key_cache then
    return api_key_cache
  end

  if not M.has_proxy() then
    return vim.env.ANTHROPIC_API_KEY or ""
  end

  local result = vim.system({ "llm-proxy-keys", "-q", "-n" }, { text = true }):wait()
  if result.code == 0 and result.stdout then
    local key = vim.trim(result.stdout)
    if key ~= "" then
      api_key_cache = key
      return api_key_cache
    end
  end

  if not warned_missing_key then
    warned_missing_key = true
    vim.schedule(function()
      vim.notify("claude_proxy: llm-proxy-keys did not return an API key", vim.log.levels.WARN)
    end)
  end

  return vim.env.ANTHROPIC_API_KEY or ""
end

local DEFAULT_PROXY_BASE = "https://internal.sofitest.com/llm-proxy"
local DEFAULT_ANTHROPIC_BASE = "https://api.anthropic.com"

-- kind: "openai" for OpenAI-compatible chat completions (avante), or
-- "messages" for the native Anthropic Messages API (minuet).
function M.endpoint(kind)
  local default_base = M.has_proxy() and DEFAULT_PROXY_BASE or DEFAULT_ANTHROPIC_BASE
  local base = (vim.env.ANTHROPIC_BASE_URL or default_base):gsub("/+$", "")

  if kind == "messages" then
    if base:match("/v1/messages$") then
      return base
    end
    if base:match("/v1$") then
      return base .. "/messages"
    end
    return base .. "/v1/messages"
  end

  if base:match("/v1$") then
    return base
  end
  return base .. "/v1"
end

return M
