local M = {}
local runtime = require("modules.core.runtime")

local ZEN_WIDTHS = { 120, 140, 160 }

local function no_neck_pain_global()
  local value = rawget(_G, "NoNeckPain")
  if type(value) == "table" then
    return value
  end
  return nil
end

local function ensure_no_neck_pain_loaded()
  if package.loaded["no-neck-pain"] then
    return true
  end

  runtime.load_config("no-neck-pain")

  if package.loaded["no-neck-pain"] then
    return true
  end

  local ok_pack = pcall(vim.cmd.packadd, "no-neck-pain.nvim")
  if not ok_pack then
    return false
  end

  return package.loaded["no-neck-pain"] ~= nil
end

local function next_zen_width(current)
  for idx, width in ipairs(ZEN_WIDTHS) do
    if width == current then
      return ZEN_WIDTHS[(idx % #ZEN_WIDTHS) + 1]
    end
  end
  return ZEN_WIDTHS[1]
end

local function no_neck_pain_module()
  if not ensure_no_neck_pain_loaded() then
    vim.notify("no-neck-pain is not available", vim.log.levels.WARN)
    return nil
  end

  local ok, nnp = pcall(require, "no-neck-pain")
  if not ok then
    vim.notify("no-neck-pain is not available", vim.log.levels.WARN)
    return nil
  end

  return nnp
end

local function is_enabled()
  local nnp = no_neck_pain_global()
  return nnp and type(nnp.state) == "table" and nnp.state.enabled == true
end

local function current_width()
  local nnp = no_neck_pain_global()
  local cfg = (nnp and type(nnp.config) == "table") and nnp.config or nil
  return tonumber((cfg and cfg.width) or vim.g.pure_zen_width or 120) or 120
end

local function set_width(target)
  local nnp = no_neck_pain_global()
  if nnp and type(nnp.config) == "table" then
    nnp.config.width = target
  end
  vim.g.pure_zen_width = target
end

local function resize_when_ready(target, attempt)
  attempt = attempt or 1
  local nnp = no_neck_pain_module()
  if not nnp then return false end

  if is_enabled() then
    local ok_resize = pcall(nnp.resize, target)
    if not ok_resize then
      vim.notify("Could not resize Zen layout in place", vim.log.levels.WARN)
    else
      vim.g.pure_zen_width = target
    end
    return ok_resize
  end

  set_width(target)

  if attempt <= 8 then
    vim.defer_fn(function()
      resize_when_ready(target, attempt + 1)
    end, 40)
  end
  return false
end

function M.toggle_zen_mode()
  local nnp = no_neck_pain_module()
  if not nnp then return end

  nnp.toggle()
end

function M.cycle_zen_width()
  local target = next_zen_width(current_width())
  resize_when_ready(target)

  vim.notify(string.format("Zen width: %d", target), vim.log.levels.INFO)
end

function M.adjust_zen_width(delta)
  local target = math.max(40, current_width() + delta)
  resize_when_ready(target)
  vim.notify(string.format("Zen width: %d", target), vim.log.levels.INFO)
end

function M.toggle_side(side)
  local nnp = no_neck_pain_module()
  if not nnp then return end
  if not is_enabled() then
    nnp.enable()
  end
  vim.defer_fn(function()
    pcall(nnp.toggle_side, side)
  end, 60)
end

function M.toggle_scratch_pad()
  local nnp = no_neck_pain_module()
  if not nnp then return end
  if not is_enabled() then
    nnp.enable()
  end
  vim.defer_fn(function()
    pcall(nnp.toggle_scratch_pad)
  end, 60)
end

function M.toggle_debug()
  local nnp = no_neck_pain_module()
  if not nnp then return end
  if not is_enabled() then
    nnp.enable()
  end
  vim.defer_fn(function()
    pcall(nnp.toggle_debug)
  end, 60)
end

return M
