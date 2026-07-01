local workspace = require("modules.lsp.workspace")

local function eslint_root(bufnr, on_dir)
  local root = vim.fs.root(bufnr, {
    "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs",
    "eslint.config.ts", "eslint.config.mts", "eslint.config.cts",
    ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json",
    "package.json",
  }) or vim.fs.root(bufnr, { "sfdx-project.json", ".git" })

  if root then
    on_dir(root)
  end
end

local function eslint_settings(root_dir)
  local settings = {
    validate = "on",
    packageManager = "npm",
    problems = {
      shortenToSingleLine = false,
    },
    rulesCustomizations = {},
    codeAction = {
      disableRuleComment = {
        enable = true,
        location = "separateLine",
      },
      showDocumentation = {
        enable = true,
      },
    },
    nodePath = vim.NIL,
    runtime = vim.NIL,
    execArgv = vim.NIL,
    useFlatConfig = false,
    experimental = { useFlatConfig = false },
    workspaceFolder = {
      uri = vim.uri_from_fname(root_dir),
      path = root_dir,
      name = vim.fn.fnamemodify(root_dir, ":t"),
    },
    workingDirectory = {
      directory = root_dir,
      changeProcessCWD = true,
    },
    workingDirectories = {
      { directory = root_dir, changeProcessCWD = true },
    },
  }

  local lwc_dir = root_dir .. "/force-app/main/default/lwc"
  if vim.fn.isdirectory(lwc_dir) == 1 then
    settings.workingDirectories[#settings.workingDirectories + 1] = { directory = lwc_dir, changeProcessCWD = true }
  end

  return settings
end

return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  cmd_env = { ESLINT_USE_FLAT_CONFIG = "false" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "html",
  },
  root_dir = eslint_root,
  build_settings = eslint_settings,
  settings = {},
  on_init = function(client)
    client.settings = client.config.settings or {}
  end,
  before_init = function(params, config)
    workspace.ensure_workspace_folders(params)

    local root_dir = config.root_dir
    if type(root_dir) ~= "string" or root_dir == "" then
      local root_uri = params.rootUri ~= vim.NIL and params.rootUri or nil
      root_dir = root_uri and vim.uri_to_fname(root_uri) or nil
    end
    if type(root_dir) ~= "string" or root_dir == "" then
      root_dir = params.rootPath ~= vim.NIL and params.rootPath or nil
    end
    if not root_dir then
      return
    end

    local root_uri = vim.uri_from_fname(root_dir)
    config.settings = vim.tbl_deep_extend("force", config.settings or {}, eslint_settings(root_dir))
    params.rootUri = root_uri
    params.rootPath = root_dir
    params.workspaceFolders = {
      {
        uri = root_uri,
        name = vim.fn.fnamemodify(root_dir, ":t"),
      },
    }

    local flat_config_files = {
      "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs",
      "eslint.config.ts", "eslint.config.mts", "eslint.config.cts",
    }

    for _, file in ipairs(flat_config_files) do
      local found = vim.fn.globpath(root_dir, file, true, true)
      for _, f in ipairs(found) do
        if not f:find("[/\\]node_modules[/\\]") then
          config.settings.experimental = config.settings.experimental or {}
          config.settings.experimental.useFlatConfig = true
          return
        end
      end
    end
  end,
}
