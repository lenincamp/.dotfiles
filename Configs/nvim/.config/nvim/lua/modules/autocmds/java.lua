local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "java", "xml" },
    group = vim.api.nvim_create_augroup("java_xml_indent", { clear = true }),
    callback = function(ev)
      vim.bo[ev.buf].tabstop = 4
      vim.bo[ev.buf].shiftwidth = 4
      vim.bo[ev.buf].softtabstop = 4
      vim.b[ev.buf].autoformat = false
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("java_execute_client_command_guard", { clear = true }),
    callback = function(args)
      if vim.g._pure_java_execute_client_command_guarded then return end

      local bufnr = args.buf
      if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then return end
      if vim.bo[bufnr].filetype ~= "java" then return end

      local client_id = args.data and args.data.client_id
      local client = client_id and vim.lsp.get_client_by_id(client_id) or nil
      if client and client.name ~= "jdtls" then return end

      local orig = vim.lsp.handlers["workspace/executeClientCommand"]
      if orig then
        vim.lsp.handlers["workspace/executeClientCommand"] = function(err, result, ctx, config)
          if ctx and ctx.bufnr and not vim.api.nvim_buf_is_valid(ctx.bufnr) then
            return
          end
          return orig(err, result, ctx, config)
        end
        vim.g._pure_java_execute_client_command_guarded = true
      end
    end,
  })

  vim.filetype.add({
    pattern = {
      [".*%.cls"] = "apex",
      [".*%.apex"] = "apex",
    },
  })
end

return M
