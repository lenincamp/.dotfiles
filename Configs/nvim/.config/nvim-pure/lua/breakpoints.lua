-- breakpoints.lua: persistent DAP breakpoints with group support (IntelliJ-style).
-- Per-project storage under stdpath("data")/breakpoints/<hash>.json
-- Groups are metadata stored in a companion <hash>.meta.json file.
--
-- Auto-save: VimLeave autocmd + explicit calls after toggle/set in nvim-dap.lua
-- Auto-load: startup (called from plugins/nvim-dap.lua) + DirChanged

local M = {}
local dirty = false  -- only true when user modifies breakpoints this session

-- ── Storage helpers ───────────────────────────────────────────────────────────

local function data_dir()
  local dir = vim.fn.stdpath("data") .. "/breakpoints"
  vim.fn.mkdir(dir, "p")
  return dir
end

local function project_root()
  local cwd = vim.fn.getcwd()
  -- Prioritise .git so monorepo subdirs always resolve to the same root.
  local git = vim.fs.find(".git", { path = cwd, upward = true })[1]
  if git then return vim.fs.dirname(git) end
  -- Fallback: build-tool markers for non-git projects.
  local marker = vim.fs.find(
    { "mvnw", "pom.xml", "build.gradle", "package.json" },
    { path = cwd, upward = true }
  )[1]
  return marker and vim.fs.dirname(marker) or cwd
end

local function project_key()
  return vim.fn.sha256(project_root()):sub(1, 12)
end

local function legacy_project_key()
  local root = vim.fs.root(0, { ".git", "mvnw", "pom.xml", "build.gradle", "package.json" })
    or vim.fn.getcwd()
  return vim.fn.sha256(root):sub(1, 12)
end

local function bp_path()  return data_dir() .. "/" .. project_key() .. ".json" end
local function meta_path() return data_dir() .. "/" .. project_key() .. ".meta.json" end
local function legacy_bp_path() return data_dir() .. "/" .. legacy_project_key() .. ".json" end

-- ── Group metadata ────────────────────────────────────────────────────────────

local function load_meta()
  local f = io.open(meta_path(), "r")
  if not f then return {} end
  local raw = f:read("*a")
  f:close()
  local ok, t = pcall(vim.json.decode, raw)
  return ok and t or {}
end

local function save_meta(meta)
  local f = io.open(meta_path(), "w")
  if f then f:write(vim.json.encode(meta)); f:close() end
end

-- Stable key for a breakpoint: "absolute_path:line"
local function bp_key(fname, line)
  return fname .. ":" .. tostring(line)
end

-- nvim-dap can return nested breakpoint tables (grouped by line).
-- Normalize to a flat list of breakpoint entries for persistence and UI.
local function iter_breakpoints(list, on_bp)
  if type(list) ~= "table" then return end
  for _, item in ipairs(list) do
    if type(item) == "table" then
      if item.line then
        on_bp(item)
      else
        for _, nested in ipairs(item) do
          if type(nested) == "table" and nested.line then
            on_bp(nested)
          end
        end
      end
    end
  end
end

-- ── Save ─────────────────────────────────────────────────────────────────────

-- Mark the session as dirty so VimLeave knows it's safe to persist.
function M.mark_dirty()
  dirty = true
end

function M.save()
  if not dirty then return end
  local ok_dap, _ = pcall(require, "dap")
  if not ok_dap then return end
  local bp_mod = require("dap.breakpoints")

  local all  = bp_mod.get()
  local data = {}
  for bufnr, list in pairs(all) do
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
    if fname ~= "" then
      local out = {}
      iter_breakpoints(list, function(bp)
        out[#out + 1] = {
          line         = bp.line,
          condition    = bp.condition,
          logMessage   = bp.logMessage,
          hitCondition = bp.hitCondition,
        }
      end)
      if #out > 0 then data[fname] = out end
    end
  end

  local f = io.open(bp_path(), "w")
  if f then f:write(vim.json.encode(data)); f:close() end
end

-- ── Load ─────────────────────────────────────────────────────────────────────

function M.load()
  local ok_dap, _ = pcall(require, "dap")
  if not ok_dap then return end

  local path = bp_path()
  local f = io.open(path, "r")
  if not f then
    local old = legacy_bp_path()
    if old ~= path then
      f = io.open(old, "r")
      path = old
    end
  end
  if not f then return end
  local raw = f:read("*a")
  f:close()

  local ok, data = pcall(vim.json.decode, raw)
  if not ok or not data then return end

  local bp_mod = require("dap.breakpoints")
  bp_mod.clear()
  local count = 0
  local silently_loaded = {}
  -- Suppress FileType so LSPs (jdtls, etc.) don't start for files the user
  -- hasn't opened. bufload is needed so line counts are correct for placement.
  local saved_ei = vim.o.eventignore
  vim.o.eventignore = "FileType,BufReadPost,BufEnter,BufWinEnter"
  for fname, list in pairs(data) do
    if vim.fn.filereadable(fname) == 1 then
      local bufnr = vim.fn.bufadd(fname)
      vim.fn.bufload(bufnr)
      silently_loaded[#silently_loaded + 1] = bufnr
      iter_breakpoints(list, function(bp)
        if not bp.line then return end
        -- nvim-dap toggle() uses snake_case keys internally,
        -- but get() returns camelCase. Map back to snake_case.
        bp_mod.set({
          condition    = bp.condition,
          log_message  = bp.logMessage,
          hit_condition = bp.hitCondition,
        }, bufnr, bp.line)
        count = count + 1
      end)
    end
  end
  vim.o.eventignore = saved_ei

  -- Re-arm filetype detection: when the user actually opens one of these
  -- buffers, BufWinEnter fires and triggers normal filetype detection.
  for _, bufnr in ipairs(silently_loaded) do
    vim.api.nvim_create_autocmd("BufWinEnter", {
      buffer   = bufnr,
      once     = true,
      callback = function() vim.cmd("filetype detect") end,
    })
  end

  if count > 0 then
    vim.notify(string.format(
      "Loaded %d breakpoint(s) [%s]", count,
      vim.fn.fnamemodify(project_root(), ":t")
    ), vim.log.levels.INFO)
  end
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

  local has_bp = false
  iter_breakpoints(require("dap.breakpoints").get(bufnr) or {}, function(bp)
    if (not has_bp) and bp.line == line then has_bp = true end
  end)
  if not has_bp then
    dap.set_breakpoint()
    vim.schedule(M.save)
  end

  vim.ui.input({ prompt = "Breakpoint group: " }, function(group)
    if not group or group == "" then return end
    local meta = load_meta()
    meta[bp_key(fname, line)] = group
    save_meta(meta)
    vim.notify("Breakpoint → group «" .. group .. "»", vim.log.levels.INFO)
  end)
end

-- ── Picker: browse all breakpoints grouped ───────────────────────────────────

-- Opens a Snacks qflist picker showing every breakpoint sorted by group,
-- then file, then line.  Navigate to any entry with <CR>.
function M.picker()
  local ok_dap, _ = pcall(require, "dap")
  if not ok_dap then return end

  local all  = require("dap.breakpoints").get()
  local meta = load_meta()
  local qf   = {}

  for bufnr, list in pairs(all) do
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
    iter_breakpoints(list, function(bp)
      local key   = bp_key(fname, bp.line)
      local group = meta[key] or "Default"
      local extra = ""
      if bp.condition and bp.condition ~= "" then
        extra = "  [cond: " .. bp.condition .. "]"
      elseif bp.logMessage and bp.logMessage ~= "" then
        extra = "  [log: "  .. bp.logMessage  .. "]"
      end
      table.insert(qf, {
        filename = fname,
        lnum     = bp.line,
        col      = 1,
        text     = string.format("[%-15s]  %s:%d%s",
          group, vim.fn.fnamemodify(fname, ":~:."), bp.line, extra),
      })
    end)
  end

  if #qf == 0 then
    vim.notify("No breakpoints in this project", vim.log.levels.INFO)
    return
  end

  table.sort(qf, function(a, b)
    local ga = a.text:match("^%[(.-)%]") or ""
    local gb = b.text:match("^%[(.-)%]") or ""
    if ga ~= gb then return ga < gb end
    if a.filename ~= b.filename then return a.filename < b.filename end
    return a.lnum < b.lnum
  end)

  vim.fn.setqflist({}, "r", { title = "Breakpoints", items = qf })

  local ok_s, Snacks = pcall(require, "snacks")
  if ok_s then Snacks.picker.qflist() else vim.cmd("copen") end
end

-- ── Setup: register autocmds ─────────────────────────────────────────────────

function M.setup()
  local ag = vim.api.nvim_create_augroup("BreakpointsPersist", { clear = true })

  vim.api.nvim_create_autocmd("VimLeave", {
    group    = ag,
    callback = M.save,
    desc     = "Auto-save breakpoints on exit",
  })

  -- Auto-load on startup (deferred so DAP is fully initialised).
  -- Safe: M.load() suppresses FileType autocmds to avoid triggering LSPs.
  vim.schedule(M.load)
end

return M
