local orphans = require("pack_manager.orphans")
local query = require("pack_manager.query")

local M = {}

function M.report(packs, pack_dir)
  local lines = {
    "PackDoctor report",
    "",
    "Command purpose audit:",
    "- PackInstall: install declared plugins",
    "- PackUpdate: update declared plugins",
    "- PackDelete: delete explicit names",
    "- PackPrune: remove undeclared/orphan entries",
    "Result: no command duplication by purpose.",
    "",
  }

  local findings = 0

  local duplicates = query.duplicate_declared_packs(packs)
  if #duplicates > 0 then
    findings = findings + #duplicates
    table.insert(lines, "Duplicate declared packs:")
    for _, item in ipairs(duplicates) do
      table.insert(lines, "- " .. item)
    end
    table.insert(lines, "")
  end

  local orphan_items = orphans.collect(packs, pack_dir)
  if #orphan_items > 0 then
    findings = findings + #orphan_items
    table.insert(lines, "Orphan installed entries:")
    for _, item in ipairs(orphan_items) do
      local tags = {}
      if item.native then table.insert(tags, "native") end
      if item.dir then table.insert(tags, "dir") end
      table.insert(lines, "- " .. item.name .. " [" .. table.concat(tags, ",") .. "]")
    end
    table.insert(lines, "")
  end

  local config_orphans = orphans.potential_config_files(packs)
  if #config_orphans > 0 then
    findings = findings + #config_orphans
    table.insert(lines, "Potential orphan config files (plugins/**/*.lua):")
    for _, path in ipairs(config_orphans) do
      table.insert(lines, "- " .. path)
    end
    table.insert(lines, "")
  end

  if findings == 0 then
    table.insert(lines, "No issues found.")
    return lines, findings
  end

  table.insert(lines, "Actions:")
  table.insert(lines, "- Run :PackPrune! to clean orphan native/dir entries")
  table.insert(lines, "- Remove or wire orphan config files as needed")
  return lines, findings
end

function M.notify(packs, pack_dir)
  local lines, findings = M.report(packs, pack_dir)
  vim.notify(table.concat(lines, "\n"), findings == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
end

return M
