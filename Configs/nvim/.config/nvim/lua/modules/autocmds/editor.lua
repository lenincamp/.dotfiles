local M = {}
local cache = {
  cwd = nil,
  files = nil,
  mtime = 0,
}

local function get_files()
  local cwd = vim.loop.cwd()

  -- simple cache por directorio
  if cache.cwd == cwd and cache.files then
    return cache.files
  end

  local output = vim
    .system({
      "fd",
      "--type",
      "f",
      "--hidden",
      "--exclude",
      ".git",
      "--exclude",
      "node_modules",
      "--exclude",
      "target",
      "--exclude",
      "dist",
      "--exclude",
      "build",
      "--exclude",
      "coverage",
      "--exclude",
      "out",
    }, { text = true })
    :wait()

  local files = vim.split(output.stdout or "", "\n", { trimempty = true })

  cache.cwd = cwd
  cache.files = files

  return files
end

function _G.my_find(text, _)
  if not text or text == "" or #text < 2 then
    return {}
  end

  local files = get_files()
  return vim.fn.matchfuzzy(files, text)
end

local function edit_netrw_hiding_list()
  vim.ui.input({
    prompt = "Edit Hiding List: ",
    default = vim.g.netrw_list_hide or "",
    scope = "buffer",
  }, function(value)
    if value == nil then
      return
    end

    vim.g.netrw_list_hide = value
    local keys = vim.api.nvim_replace_termcodes("<Plug>NetrwRefresh", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = "*",
    group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
    callback = function()
      vim.highlight.on_yank({ timeout = 200 })
    end,
  })
  vim.opt.findfunc = "v:lua.my_find"
  vim.opt.wildmode = "noselect"
  vim.opt.wildoptions = "pum,fuzzy"
  vim.api.nvim_create_autocmd("CmdlineChanged", {
    pattern = ":",
    callback = function()
      vim.fn.wildtrigger()
    end,
  })
  vim.api.nvim_create_autocmd("CmdlineChanged", {
    pattern = "/",
    callback = function()
      vim.fn.wildtrigger()
    end,
  })

  vim.api.nvim_create_user_command("Rg", function(opts)
    local lines = vim.fn.systemlist({ "rg", "--vimgrep", "-F", opts.args })
    vim.fn.setqflist({}, "r", {
      title = "Search: " .. opts.args,
      lines = lines,
    })
    vim.cmd.copen(10)
  end, { nargs = 1 })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("pure_netrw_split_navigation", { clear = true }),
    pattern = "netrw",
    callback = function(args)
      vim.keymap.set("n", "<leader>er", "<Plug>NetrwRefresh", {
        buffer = args.buf,
        remap = true,
        silent = true,
        desc = "Netrw: refresh directory listing",
      })
      vim.keymap.set("n", "<leader>eh", edit_netrw_hiding_list, {
        buffer = args.buf,
        silent = true,
        desc = "Netrw: edit file hiding list",
      })
      vim.keymap.set("n", "<C-l>", function()
        require("pure-ui.split_nav").move("l")
      end, { buffer = args.buf, silent = true, nowait = true, desc = "Move to right window" })
    end,
  })
end

return M
