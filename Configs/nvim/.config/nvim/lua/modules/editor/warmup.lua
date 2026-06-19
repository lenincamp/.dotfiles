local M = {}

local MINUET_WARMUP_MS = 350
local BLINK_WARMUP_MS = 500
local AVANTE_WARMUP_MS = 1200

local function safe_load(load_cfg_once, name)
  local ok, loaded = pcall(load_cfg_once, name)
  return ok and loaded
end

local function warmup_avante(load_cfg_once, attempt)
  if attempt > 6 then
    return
  end

  if not safe_load(load_cfg_once, "minuet") then
    vim.defer_fn(function()
      warmup_avante(load_cfg_once, attempt + 1)
    end, 900)
    return
  end

  if safe_load(load_cfg_once, "avante") then
    return
  end

  vim.defer_fn(function()
    warmup_avante(load_cfg_once, attempt + 1)
  end, 1400)
end

function M.setup(load_cfg_once)
  if type(load_cfg_once) ~= "function" then
    return
  end

  if vim.g.pure_disable_async_warmup == true then
    return
  end

  local function start_warmup()
    if vim.opt.diff:get() then
      return
    end

    vim.defer_fn(function()
      safe_load(load_cfg_once, "minuet")
    end, MINUET_WARMUP_MS)

    vim.defer_fn(function()
      safe_load(load_cfg_once, "blink-cmp")
    end, BLINK_WARMUP_MS)

    vim.defer_fn(function()
      warmup_avante(load_cfg_once, 1)
    end, AVANTE_WARMUP_MS)
  end

  if vim.v.vim_did_enter == 1 then
    start_warmup()
    return
  end

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("PureAsyncWarmup", { clear = true }),
    once = true,
    callback = start_warmup,
  })
end

return M
