local M = {}

-- Normalize workspaceFolders before initialize to avoid Node LSP crashes
-- when params.workspaceFolders arrives as vim.NIL (JSON null).
function M.ensure_workspace_folders(params)
  local wf = params.workspaceFolders
  if (wf ~= nil) and (wf ~= vim.NIL) and not (type(wf) == "table" and #wf == 0) then
    return
  end

  local uri = params.rootUri
  if uri == nil or uri == vim.NIL then
    uri = vim.uri_from_fname(vim.fn.getcwd())
    params.rootUri = uri
  end

  params.workspaceFolders = {
    {
      uri = uri,
      name = vim.fn.fnamemodify(vim.uri_to_fname(uri), ":t"),
    },
  }
end

return M
