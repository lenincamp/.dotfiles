local M = {}

local persistence = require("modules.dap.breakpoints.persistence")
local state = require("modules.dap.breakpoints.state")
local storage = require("modules.dap.breakpoints.storage")

local iter_breakpoints = persistence.iter_breakpoints

function M.has_saved_project()
  local dir = storage.storage_dir()
  return vim.fn.filereadable(dir .. "/" .. storage.project_key() .. ".json") == 1
end

local function icon(bp)
  if bp.logMessage and bp.logMessage ~= "" then return "◉" end
  if bp.condition and bp.condition ~= "" then return "◆" end
  if bp.hitCondition and bp.hitCondition ~= "" then return "◇" end
  return "●"
end

function M.collect()
  local all = require("dap.breakpoints").get()
  local meta = storage.load_meta(state.active_project_key)
  local items = {}

  for bufnr, list in pairs(all) do
    if type(bufnr) == "number" and vim.api.nvim_buf_is_valid(bufnr) then
      local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
      if fname ~= "" then
        iter_breakpoints(list, function(bp)
          local key = storage.bp_key(fname, bp.line)
          items[#items + 1] = {
            bufnr = bufnr,
            filename = fname,
            line = bp.line,
            group = meta[key] or "Default",
            condition = bp.condition,
            log_message = bp.logMessage,
            hit_condition = bp.hitCondition,
            key = key,
            icon = icon(bp),
          }
        end)
      end
    end
  end

  table.sort(items, function(a, b)
    if a.group ~= b.group then return a.group < b.group end
    if a.filename ~= b.filename then return a.filename < b.filename end
    return a.line < b.line
  end)

  return items
end

function M.set_breakpoint(item, opts)
  local bp_mod = require("dap.breakpoints")
  bp_mod.remove(item.bufnr, item.line)
  bp_mod.set({
    condition = opts.condition,
    log_message = opts.log_message,
    hit_condition = opts.hit_condition,
  }, item.bufnr, item.line)
  persistence.mark_dirty()
  persistence.save({ force = true })
end

return M
