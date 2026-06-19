local model = require("modules.editor.keymap_docs.model")

local M = {}

function M.select(items_fn)
  local source_items = items_fn()
  local items = {}
  local current_group = nil

  for _, item in ipairs(source_items) do
    if item.group ~= current_group then
      current_group = item.group
      items[#items + 1] = {
        source = "group",
        mode = "",
        keys = "",
        desc = current_group,
        group = current_group,
      }
    end
    items[#items + 1] = item
  end

  require("modules.editor.picker").select_items(items, {
    prompt = "Keymaps",
    scope = "global",
    search_threshold = 0,
    group_item = function(item) return item.group end,
    format_item = function(item)
      if item.source == "group" then
        return string.format("▾ %s", item.group)
      end
      return string.format("  ├─ %-16s  %s  %-4s  %s", model.normalize_lhs(item.keys), item.mode, item.source, item.desc)
    end,
  }, function(item)
    if not item then return end
    if item.source == "group" then return end
    if item.source == "map" and item.mode == "n" then
      local keys = vim.api.nvim_replace_termcodes(item.keys, true, false, true)
      vim.api.nvim_feedkeys(keys, "m", false)
    else
      vim.notify(string.format("%s %s %s", item.mode, item.keys, item.desc), vim.log.levels.INFO)
    end
  end)
end

function M.open_docs(items_fn)
  local lines = { "# Keymap Docs", "" }
  for _, item in ipairs(items_fn()) do
    lines[#lines + 1] = string.format("%-2s %-18s %-4s %s", item.mode, model.normalize_lhs(item.keys), item.source, item.desc)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Keymap Docs")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, buf)
end

return M
