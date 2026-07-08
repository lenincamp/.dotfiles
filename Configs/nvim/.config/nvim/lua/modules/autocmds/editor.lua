local M = {}
local cache = {
  cwd = nil,
  files = nil,
  mtime = 0,
}

local function get_files()
  local cwd = vim.loop.cwd()
  if cache.cwd == cwd and cache.files then
    return cache.files
  end
  local fd = require("modules.editor.fd")
  local output = vim.system(vim.list_extend({ "fd", "--type", "f" }, fd.basic()), { text = true }):wait()
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
    local cmd = { "rg", "--vimgrep", "-F" }
    vim.list_extend(cmd, opts.fargs)
    local lines = vim.fn.systemlist(cmd)
    local text = table.concat(opts.fargs, " ")
    if not lines or #lines == 0 then
      vim.notify("There aren't results for " .. text, vim.log.levels.WARN)
      return
    end
    require("modules.editor.search_qf").set_to_qflist("Search: " .. text, nil, lines, { type = "search" })
  end, { nargs = "+" })

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
        require("modules.editor.split_nav").move("l")
      end, { buffer = args.buf, silent = true, nowait = true, desc = "Move to right window" })
    end,
  })

  vim.api.nvim_create_user_command("Td", function()
    require("floatodo").floatodo_toggle()
  end, { desc = "Toggle Floating TODO" })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function(args)
      local ctx = vim.fn.getqflist({ context = 1 }).context
      if ctx and ctx.type == "git" then
        vim.keymap.set("n", "<CR>", require("modules.git.native").git_open, {
          buffer = args.buf,
          silent = true,
        })
        return
      end
      pcall(vim.keymap.del, "n", "<CR>", { buffer = args.buf })
    end,
  })
  local default_showtabline = vim.o.showtabline
  vim.api.nvim_create_autocmd("TermOpen", {
    callback = function()
      vim.t.has_terminal = true
      vim.o.showtabline = 0
    end,
  })
  vim.api.nvim_create_autocmd("TabEnter", {
    callback = function()
      vim.o.showtabline = vim.t.has_terminal and 0 or default_showtabline
    end,
  })
end

return M
