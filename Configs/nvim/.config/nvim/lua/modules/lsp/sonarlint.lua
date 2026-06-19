local M = {}

local mason_sonar = vim.fn.expand("~/.local/share/nvim/mason/bin/sonarlint-language-server")
local enabled = false
local group = vim.api.nvim_create_augroup("pure_native_sonarlint", { clear = true })

local supported_filetypes = {
  java = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  python = true,
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "SonarLint" })
end

local function root_dir(bufnr)
  return vim.fs.root(bufnr, { "sonar-project.properties", "pom.xml", "package.json", ".git" }) or vim.fn.getcwd()
end

local function config(bufnr)
  return {
    name = "sonarlint",
    cmd = { mason_sonar, "-stdio" },
    root_dir = root_dir(bufnr),
    filetypes = vim.tbl_keys(supported_filetypes),
  }
end

local function attach(bufnr)
  if not enabled or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if vim.bo[bufnr].buftype ~= "" or not supported_filetypes[vim.bo[bufnr].filetype] then
    return
  end
  if vim.fn.filereadable(mason_sonar) == 0 then
    notify("sonarlint-language-server not found. Run :MasonInstall sonarlint-language-server", vim.log.levels.WARN)
    return
  end
  vim.lsp.start(config(bufnr), { bufnr = bufnr })
end

local function stop_clients()
  for _, client in ipairs(vim.lsp.get_clients({ name = "sonarlint" })) do
    client:stop(true)
  end
end

function M.enable()
  enabled = true
  attach(vim.api.nvim_get_current_buf())
  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = group,
    callback = function(args)
      attach(args.buf)
    end,
  })
  notify("enabled")
end

function M.disable()
  enabled = false
  vim.api.nvim_clear_autocmds({ group = group })
  stop_clients()
  notify("disabled")
end

function M.toggle()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.is_enabled()
  return enabled
end

return M
