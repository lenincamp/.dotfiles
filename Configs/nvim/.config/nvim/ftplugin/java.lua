-- Java ftplugin: indent, guards, and JDTLS lifecycle.

vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.b.autoformat = false

-- Guard: prevent executeClientCommand crash on invalid buffers (once globally)
if not vim.g._pure_java_execute_client_command_guarded then
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
end

-- JDTLS attach: handled by jdtls.nvim/ftplugin/java.lua (do not call attach here — double start)
