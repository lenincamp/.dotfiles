-- ── Per-server configuration (Neovim 0.11+ native API) ──────────────────────
-- These override / extend the defaults provided by nvim-lspconfig.

-- ── Shared helpers ────────────────────────────────────────────────────────────

-- Neovim sends workspaceFolders = vim.NIL (JSON null) when workspace_folders
-- is nil on the client.  Several Node-based servers (vtsls, eslint) call
-- null.map() internally and crash with:
--   "Cannot read properties of null (reading 'map')"
-- This normalizes the field before the initialize request is sent.
local function ensure_workspace_folders(params)
  local wf = params.workspaceFolders
  if (wf ~= nil) and (wf ~= vim.NIL) and not (type(wf) == "table" and #wf == 0) then
    return -- already valid
  end
  local uri = params.rootUri
  if uri == nil or uri == vim.NIL then
    uri = vim.uri_from_fname(vim.fn.getcwd())
    params.rootUri = uri
  end
  params.workspaceFolders = {{
    uri  = uri,
    name = vim.fn.fnamemodify(vim.uri_to_fname(uri), ":t"),
  }}
end

-- ── Server configs ────────────────────────────────────────────────────────────

vim.lsp.config("tailwindcss", {
  -- Only attach when a tailwind config exists in the project root.
  root_markers = {
    "tailwind.config.js", "tailwind.config.ts",
    "tailwind.config.cjs", "tailwind.config.mjs",
  },
  -- Restrict to files where Tailwind classes are actually used.
  -- Plain 'javascript' / 'typescript' (hooks, utils, stores) are excluded:
  -- v0.14.x crashes with "Cannot read properties of null (reading 'map')"
  -- on JS files that have no JSX/HTML content.
  filetypes = {
    "html", "css", "scss", "less",
    "javascriptreact",    -- .jsx
    "typescriptreact",    -- .tsx
    "svelte", "vue",
  },
})

vim.lsp.config("vtsls", {
  -- Root at the nearest tsconfig/jsconfig to fix monorepo initialization.
  root_dir = function(bufnr, on_dir)
    if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then return end
    local root = vim.fs.root(bufnr, { "tsconfig.json", "jsconfig.json" })
      or vim.fs.root(bufnr, { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb" })
      or vim.fs.root(bufnr, { ".git" })
      or vim.fn.getcwd()
    on_dir(root)
  end,
  before_init = ensure_workspace_folders,
  settings = {
    javascript = { preferences = { importModuleSpecifier = "non-relative" } },
    typescript = { preferences = { importModuleSpecifier = "non-relative" } },
  },
})

vim.lsp.config("lemminx", {
  init_options = {
    settings = {
      xml = {
        format = {
          enabled           = true,
          joinContentLines  = true,
          preservedNewlines = 1,
          insertSpaces      = true,
          tabSize           = 4,
        },
      },
    },
  },
})

vim.lsp.config("apex_ls", {
  init_options = {
    apex_jar_path                   = vim.fn.stdpath("data") .. "/mason/share/apex-language-server/apex-jorje-lsp.jar",
    apex_enable_semantic_errors     = true,
    apex_enable_completion_statistics = false,
  },
})

vim.lsp.config("lwc_ls", {
  cmd        = { "lwc-language-server", "--stdio" },
  filetypes  = { "javascript", "html" },
  -- Only start when inside a Salesforce project. Without this guard,
  -- lwc_ls starts for ANY .js file, gets null workspaceFolders, and crashes
  -- with "Cannot read properties of null (reading 'map')".
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "sfdx-project.json" })
    if not root then return end
    on_dir(root)
  end,
  before_init = ensure_workspace_folders,
  init_options = { embeddedLanguages = { javascript = true } },
})

vim.lsp.config("visualforce_ls", {
  filetypes    = { "visualforce" },
  root_markers = { "sfdx-project.json" },
  init_options = { embeddedLanguages = { css = true, javascript = true } },
})

-- Override only before_init for eslint. Everything else (root_dir, settings,
-- handlers) comes from lspconfig's battle-tested default which already handles
-- monorepos (lockfile root, eslint config ancestry check, Deno exclusion, etc).
vim.lsp.config("eslint", {
  -- Force ESLint v9 into legacy (.eslintrc) mode via env var. The server's
  -- experimental.useFlatConfig setting alone isn't reliable with ESLint v9+.
  cmd_env = { ESLINT_USE_FLAT_CONFIG = "false" },
  -- Our before_init replaces lspconfig's (functions can't be deep-merged), so
  -- we must replicate its workspaceFolder + flat-config logic here.
  before_init = function(params, config)
    -- Prevent "Cannot read properties of null (reading 'map')" crash.
    ensure_workspace_folders(params)

    -- Replicate lspconfig/lsp/eslint.lua before_init logic.
    local root_dir = config.root_dir
    if not root_dir then return end

    config.settings = config.settings or {}
    config.settings.workspaceFolder = {
      uri  = root_dir,
      name = vim.fn.fnamemodify(root_dir, ":t"),
    }

    -- Detect flat config (eslint.config.*) at the project root.
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
})

vim.lsp.config("lua_ls", {
  filetypes = { "lua" },
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },  -- Neovim 'vim' global
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),  -- include Neovim runtime
      },
      completion = {
        callSnippet = "Replace",
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- ── Enable all servers ────────────────────────────────────────────────────────
-- lua_ls: enabled on-demand when a Lua file is detected (see plugins.lua)

if not vim.opt.diff:get() then
  vim.lsp.enable({
  "tailwindcss",
  "kotlin_language_server",
  "vtsls",
  "lemminx",
  "apex_ls",
  "lwc_ls",
  "visualforce_ls",
  "vimls",
  "eslint",
  })
end

-- ── Diagnostics — ErrorLens style (Neovim 0.10+ native) ─────────────────────
-- virtual_text   : short prefix always visible on every diagnostic line
-- virtual_lines  : FULL message shown below the current line (like ErrorLens)
--                  only_current_line = true avoids clutter on every line
-- Toggle: <leader>ul (line numbers) / <leader>uv (virtual lines)
--
-- Icons (nerd font) by severity:

local diag_icons = { Error = "", Warn = "", Info = "", Hint = "󰌵 "}

vim.diagnostic.config({
  signs           = {
    text = {
      [vim.diagnostic.severity.ERROR] = diag_icons.Error,
      [vim.diagnostic.severity.WARN]  = diag_icons.Warn,
      [vim.diagnostic.severity.INFO]  = diag_icons.Info,
      [vim.diagnostic.severity.HINT]  = diag_icons.Hint,
    },
  },
  -- Signs in gutter only. Detail appears via CursorHold float (see autocmds.lua).
  virtual_text    = false,
  virtual_lines   = false,
  underline       = true,
  update_in_insert = false,
  severity_sort   = true,
  float           = {
    border  = "rounded",
    source  = true,                -- show source (e.g. "eslint" or "jdtls")
    header  = "",
    prefix  = function(diag)
      local icon = diag_icons[vim.diagnostic.severity[diag.severity]] or "● "
      return icon, "DiagnosticSign" .. vim.diagnostic.severity[diag.severity]
    end,
  },
})

