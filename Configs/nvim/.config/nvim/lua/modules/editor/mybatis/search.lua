local M = {}

local shell = require("modules.core.shell")

local function run_command(args)
  local lines, code = shell.systemlist(args)
  if code ~= 0 then
    return {}
  end
  return lines
end

function M.rg_files(root, glob)
  return run_command({
    "rg",
    "--files",
    "--glob",
    glob,
    root,
  })
end

function M.rg_files_with_matches(pattern, root, glob)
  return run_command({
    "rg",
    "--files-with-matches",
    "--smart-case",
    "--glob",
    glob,
    "--",
    pattern,
    root,
  })
end

function M.rg_vimgrep(pattern, paths, opts)
  opts = opts or {}

  local args = {
    "rg",
    "--vimgrep",
    "--smart-case",
  }

  if opts.fixed_strings then
    table.insert(args, "--fixed-strings")
  end

  if opts.glob and opts.glob ~= "" then
    table.insert(args, "--glob")
    table.insert(args, opts.glob)
  end

  table.insert(args, "--")
  table.insert(args, pattern)

  if type(paths) == "string" then
    table.insert(args, paths)
  else
    for _, path in ipairs(paths) do
      table.insert(args, path)
    end
  end

  return run_command(args)
end

function M.parse_vimgrep_lines(lines)
  local items = {}
  for _, line in ipairs(lines) do
    local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
    if filename and lnum and col then
      table.insert(items, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
      })
    end
  end
  return items
end

function M.first_vimgrep_item(lines)
  local items = M.parse_vimgrep_lines(lines)
  if vim.tbl_isempty(items) then
    return nil
  end
  return items[1]
end

return M
