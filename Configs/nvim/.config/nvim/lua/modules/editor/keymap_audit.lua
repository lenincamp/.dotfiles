local M = {}

local MODES = { "n", "i", "x", "s", "o", "t" }

local function signature(map)
  return table.concat({
    map.rhs or "",
    tostring(map.callback ~= nil),
    map.desc or "",
    tostring(map.sid or ""),
    tostring(map.lnum or ""),
  }, "|")
end

local function add_maps(buckets, maps, scope)
  for _, map in ipairs(maps) do
    local mode = map.mode or scope.mode
    local lhs = map.lhs
    if lhs and lhs ~= "" then
      local key = table.concat({ mode, lhs, scope.kind }, "\t")
      buckets[key] = buckets[key] or {
        mode = mode,
        lhs = lhs,
        scope = scope.kind,
        signatures = {},
        entries = {},
      }
      local sig = signature(map)
      buckets[key].signatures[sig] = true
      buckets[key].entries[#buckets[key].entries + 1] = {
        desc = map.desc or "",
        rhs = map.rhs or "",
        callback = map.callback ~= nil,
        script = map.script == 1,
        sid = map.sid,
        lnum = map.lnum,
      }
    end
  end
end

local function signature_count(signatures)
  local count = 0
  for _ in pairs(signatures) do
    count = count + 1
  end
  return count
end

function M.collect(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local buckets = {}

  for _, mode in ipairs(MODES) do
    add_maps(buckets, vim.api.nvim_get_keymap(mode), { mode = mode, kind = "global" })
    if vim.api.nvim_buf_is_valid(bufnr) then
      add_maps(buckets, vim.api.nvim_buf_get_keymap(bufnr, mode), { mode = mode, kind = "buffer" })
    end
  end

  return buckets
end

function M.conflicts(bufnr)
  local conflicts = {}
  for _, bucket in pairs(M.collect(bufnr)) do
    if signature_count(bucket.signatures) > 1 then
      conflicts[#conflicts + 1] = bucket
    end
  end

  table.sort(conflicts, function(a, b)
    if a.mode ~= b.mode then return a.mode < b.mode end
    if a.scope ~= b.scope then return a.scope < b.scope end
    return a.lhs < b.lhs
  end)

  return conflicts
end

function M.report(bufnr)
  local conflicts = M.conflicts(bufnr)
  local lines = {
    "# Keymap Audit",
    "",
    string.format("Conflicting duplicates: %d", #conflicts),
  }

  for _, conflict in ipairs(conflicts) do
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("## %s %s (%s)", conflict.mode, conflict.lhs, conflict.scope)
    for index, entry in ipairs(conflict.entries) do
      lines[#lines + 1] = string.format(
        "%d. desc=%s rhs=%s callback=%s sid=%s lnum=%s",
        index,
        entry.desc ~= "" and entry.desc or "-",
        entry.rhs ~= "" and entry.rhs or "-",
        tostring(entry.callback),
        tostring(entry.sid or "-"),
        tostring(entry.lnum or "-")
      )
    end
  end

  return lines, conflicts
end

function M.open_report()
  local lines, conflicts = M.report(0)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "markdown"
  vim.api.nvim_buf_set_name(bufnr, "Keymap Audit")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, bufnr)

  if #conflicts == 0 then
    vim.notify("Keymap audit: no conflicting duplicates", vim.log.levels.INFO)
  else
    vim.notify("Keymap audit: conflicts found", vim.log.levels.WARN)
  end
end

function M.assert_clean(bufnr)
  local conflicts = M.conflicts(bufnr or 0)
  if #conflicts > 0 then
    local labels = {}
    for _, conflict in ipairs(conflicts) do
      labels[#labels + 1] = string.format("%s %s (%s)", conflict.mode, conflict.lhs, conflict.scope)
    end
    error("Conflicting keymaps: " .. table.concat(labels, ", "))
  end
  return true
end

function M.setup()
  vim.api.nvim_create_user_command("KeymapAudit", M.open_report, { desc = "Audit keymaps for conflicting duplicates" })
end

return M
