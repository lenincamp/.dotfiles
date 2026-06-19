-- breakpoints.lua: persistent DAP breakpoints with group support (IntelliJ-style).
-- Per-project storage under stdpath("data")/breakpoints/<hash>.json
-- Groups are metadata stored in a companion <hash>.meta.json file.
--
-- Auto-save: VimLeave autocmd + explicit calls after toggle/set in nvim-dap.lua
-- Auto-load: startup (called from plugins/nvim-dap.lua) + DirChanged

local M = {}
local hooks = require("modules.dap.breakpoints.hooks")
local persistence = require("modules.dap.breakpoints.persistence")
local picker = require("modules.dap.breakpoints.picker")
local storage = require("modules.dap.breakpoints.storage")
local state = require("modules.dap.breakpoints.state")

-- ── Public facade ─────────────────────────────────────────────────────────────

function M.has_saved_project()
  local dir = storage.storage_dir()
  return vim.fn.filereadable(dir .. "/" .. storage.project_key() .. ".json") == 1
end

local iter_breakpoints = persistence.iter_breakpoints

M.mark_dirty = persistence.mark_dirty
M.save = persistence.save
M.load = persistence.load
M.setup = hooks.setup
M.picker = picker.open

function M.save_async()
  vim.schedule(function()
    pcall(function()
      M.mark_dirty()
      M.save()
    end)
  end)
end

function M.icon_for(lnum_str, path)
  local ok_bp, dap_bp = pcall(require, "dap.breakpoints")
  if not ok_bp then return "●" end
  local lnum = tonumber(lnum_str)
  for bufnr, entries in pairs(dap_bp.get() or {}) do
    local buffer_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
    if buffer_name == path then
      for _, breakpoint in ipairs(entries) do
        if breakpoint.line == lnum then
          if breakpoint.logMessage and breakpoint.logMessage ~= "" then return "◉" end
          if breakpoint.condition and breakpoint.condition ~= "" then return "◆" end
          if breakpoint.hitCondition and breakpoint.hitCondition ~= "" then return "◇" end
          return "●"
        end
      end
    end
  end
  return "●"
end

function M.short_path(path)
  local parts = vim.split(path, "/")
  if #parts <= 3 then return path end
  return parts[#parts - 1] .. "/" .. parts[#parts]
end

-- ── Assign group ─────────────────────────────────────────────────────────────

-- Assigns (or reassigns) the breakpoint on the current line to a named group.
-- Creates the breakpoint first if none exists on that line.
function M.assign_group()
  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local line  = vim.api.nvim_win_get_cursor(0)[1]
  local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")

  local bp_mod = require("dap.breakpoints")
  local by_buf = bp_mod.get(bufnr) or {}
  local has_bp = false
  iter_breakpoints(by_buf[bufnr] or by_buf, function(bp)
    if (not has_bp) and bp.line == line then has_bp = true end
  end)
  if not has_bp then
    dap.set_breakpoint()
    vim.schedule(M.save)
  end

  vim.ui.input({ prompt = "Breakpoint group: ", scope = "line" }, function(group)
    if not group or group == "" then return end
    local meta = storage.load_meta(state.active_project_key)
    meta[storage.bp_key(fname, line)] = group
    storage.save_meta(meta, state.active_project_key)
    vim.notify("Breakpoint → group «" .. group .. "»", vim.log.levels.INFO)
  end)
end

return M
