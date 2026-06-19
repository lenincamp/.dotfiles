local M = {}

local baseline
local overrides = {}

local function ensure_baseline()
  if baseline then
    return
  end

  baseline = {
    lazyredraw = vim.o.lazyredraw,
    updatetime = vim.o.updatetime,
    redrawtime = vim.o.redrawtime,
  }
end

function M.recompute()
  ensure_baseline()

  local lazyredraw = baseline.lazyredraw
  local updatetime = baseline.updatetime
  local redrawtime = baseline.redrawtime

  for _, opts in pairs(overrides) do
    if opts.lazyredraw ~= nil then
      lazyredraw = lazyredraw or opts.lazyredraw
    end
    if type(opts.updatetime) == "number" then
      updatetime = math.max(updatetime, opts.updatetime)
    end
    if type(opts.redrawtime) == "number" then
      redrawtime = math.max(redrawtime, opts.redrawtime)
    end
  end

  vim.o.lazyredraw = lazyredraw
  vim.o.updatetime = updatetime
  vim.o.redrawtime = redrawtime
end

function M.set(key, opts)
  if type(key) ~= "string" or key == "" then
    return
  end

  overrides[key] = opts or {}
  M.recompute()
end

function M.clear(key)
  overrides[key] = nil
  M.recompute()
end

return M
