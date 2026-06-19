local M = {}

function M.normalize_lhs(lhs)
  return (lhs or ""):gsub("<space>", "<Space>"):gsub(" ", "<Space>")
end

function M.group_lhs(lhs)
  lhs = M.normalize_lhs(lhs)
  lhs = lhs:gsub("<leader>", "<Leader>")
  if lhs:sub(1, 7) == "<Space>" then
    return "<Leader>" .. lhs:sub(8)
  end
  return lhs
end

function M.item_key(mode, keys)
  return mode .. "\0" .. M.group_lhs(keys)
end

function M.group_for(item)
  local keys = M.group_lhs(item.keys)
  local desc = item.desc or ""
  if desc:sub(1, 1) == "+" then return desc:sub(2) end
  if keys:match("^<Leader>a") then return "AI" end
  if keys:match("^<Leader>D") then return "Database" end
  if keys:match("^<Leader>b") then return "Buffers" end
  if keys:match("^<Leader>c") then return "Code" end
  if keys:match("^<Leader>d") then return "Debug" end
  if keys:match("^<Leader>f") or keys == "<Leader>e" or keys == "<Leader>E" then return "Files/Terminal" end
  if keys:match("^<Leader>g") then return "Git" end
  if keys:match("^<Leader>J") then return "Java" end
  if keys:match("^<Leader>m") then return "MyBatis" end
  if keys:match("^<Leader>p") then return "Project/Sessions" end
  if keys:match("^<Leader>r") then return "Refactor" end
  if keys:match("^<Leader>s") then return "Search" end
  if keys:match("^<Leader>S") then return "Salesforce" end
  if keys:match("^<Leader>t") then return "Tests" end
  if keys:match("^<Leader>u") then return "UI" end
  if keys:match("^<Leader>w") then return "Windows" end
  if keys:match("^<Leader>x") then return "Lists" end
  if keys:match("^<Leader><Tab>") then return "Tabs" end
  if keys:match("^g") then return "g-prefix/LSP" end
  if keys:match("^z") then return "Folds/View" end
  if keys:match("^[%[%]]") then return "Bracket Navigation" end
  if keys:match("^s") then return "Surround/Flash" end
  if keys:match("^d") then return "Diff" end
  return "Vim Default"
end

function M.actual_keymaps()
  local items = {}
  for _, mode in ipairs({ "n", "i", "x", "o", "t" }) do
    for _, item in ipairs(vim.api.nvim_get_keymap(mode)) do
      items[#items + 1] = {
        source = "map",
        mode = mode,
        keys = item.lhs,
        desc = item.desc or item.rhs or "",
        group = M.group_for({ keys = item.lhs, desc = item.desc or item.rhs or "" }),
      }
    end
  end
  return items
end

function M.doc_items(extra_docs, spec_docs)
  local items = {}
  local seen = {}

  for _, item in ipairs(spec_docs or require("modules.editor.keymap_specs").docs()) do
    local key = M.item_key(item.mode, item.keys)
    seen[key] = true
    items[#items + 1] = {
      source = item.source or "spec",
      mode = item.mode,
      keys = item.keys,
      desc = item.desc,
      group = item.group or M.group_for(item),
    }
  end

  for _, item in ipairs(extra_docs or {}) do
    local key = item.group and (M.item_key(item.mode, item.keys) .. "\0" .. item.group) or M.item_key(item.mode, item.keys)
    if not seen[key] then
      seen[key] = true
      items[#items + 1] = {
        source = item.source or "doc",
        mode = item.mode,
        keys = item.keys,
        desc = item.desc,
        group = item.group or M.group_for(item),
      }
    end
  end
  return items
end

function M.items(extra_docs)
  local items_by_key = {}
  local order = {}

  local function add_item(item)
    local key = M.item_key(item.mode, item.keys)
    local existing = items_by_key[key]
    if not existing then
      items_by_key[key] = vim.tbl_extend("force", {}, item)
      order[#order + 1] = key
      return
    end

    if item.source == "map" then
      local previous_source = existing.source or "doc"
      existing.source = previous_source:find("map", 1, true) and previous_source or ("map+" .. previous_source)
      existing.desc = item.desc ~= "" and item.desc or existing.desc
      existing.group = existing.group or item.group
      return
    end

    if existing.source == "map" then
      existing.source = "map+" .. (item.source or "doc")
      existing.group = existing.group or item.group
      if existing.desc == "" then
        existing.desc = item.desc
      end
      return
    end
  end

  for _, item in ipairs(M.doc_items(extra_docs)) do
    add_item(item)
  end
  for _, item in ipairs(M.actual_keymaps()) do
    add_item(item)
  end

  local items = {}
  for _, key in ipairs(order) do
    items[#items + 1] = items_by_key[key]
  end
  table.sort(items, function(a, b)
    if a.group ~= b.group then
      return a.group < b.group
    end
    if a.mode ~= b.mode then
      return a.mode < b.mode
    end
    if a.keys ~= b.keys then
      return a.keys < b.keys
    end
    return a.source < b.source
  end)
  return items
end

return M
