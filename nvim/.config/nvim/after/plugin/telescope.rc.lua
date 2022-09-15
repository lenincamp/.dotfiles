local status, telescope = pcall(require, "telescope")
if (not status) then return end
local actions = require('telescope.actions')
local builtin = require("telescope.builtin")

local function telescope_buffer_dir()
  return vim.fn.expand('%:p:h')
end

local fb_actions = require "telescope".extensions.file_browser.actions

telescope.setup {
  defaults = {
    mappings = {
      n = {
        ["q"] = actions.close
      },
    },
  },
  extensions = {
    file_browser = {
      theme = "dropdown",
      -- disables netrw and use telescope-file-browser in its place
      hijack_netrw = true,
      mappings = {
        -- your custom insert mode mappings
        ["i"] = {
          ["<C-w>"] = function() vim.cmd('normal vbd') end,
        },
        ["n"] = {
          -- your custom normal mode mappings
          ["%"] = fb_actions.create,
          ["-"] = fb_actions.goto_parent_dir,
          ["/"] = function()
            vim.cmd('startinsert')
          end
        },
      },
    },
  },
}

telescope.load_extension("file_browser")
telescope.load_extension("neoclip")

vim.keymap.set('n', ';f',
  function()
    builtin.find_files({
      no_ignore = false,
      hidden = true,
      layout_strategy = 'vertical', layout_config = { preview_height = 26 }

    })
  end)
vim.keymap.set('n', ';r', function()
  builtin.live_grep({
    layout_strategy = 'vertical', layout_config = { preview_height = 26 }
  })
end)
vim.keymap.set('n', '\\\\', function()
  builtin.buffers()
end)
vim.keymap.set('n', ';t', function()
  builtin.help_tags({ initial_mode = "normal",
    layout_strategy = 'vertical', layout_config = { preview_height = 30 } })
end)
vim.keymap.set('n', ';;', function()
  builtin.resume()
end)
vim.keymap.set('n', ';e', function()
  builtin.diagnostics({ initial_mode = "normal", layout_strategy = 'vertical', layout_config = { preview_height = 26 } })
end)
vim.keymap.set("n", "sf", function()
  telescope.extensions.file_browser.file_browser({
    path = "%:p:h",
    cwd = telescope_buffer_dir(),
    respect_gitignore = false,
    hidden = true,
    grouped = true,
    previewer = false,
    initial_mode = "normal",
    layout_config = { height = 40 }
  })
end)

--document simbols
vim.keymap.set('n', ';ds', function()
  builtin.lsp_document_symbols()
end)

-- git_branches
vim.keymap.set('n', 'gb', function()
  builtin.git_branches { prompt_title = ' ', initial_mode = "normal",
    layout_strategy = 'vertical', layout_config = { preview_height = 30 } }
end)

-- git_bcommits - file/buffer scoped commits to vsp diff
vim.keymap.set('n', ';gc', function()
  builtin.git_bcommits { prompt_title = '  ', initial_mode = "normal",
    layout_strategy = 'vertical', layout_config = { preview_height = 30 } }
end)

-- git_commits (log) git log
vim.keymap.set('n', 'gc', function()
  builtin.git_commits { prompt_title = '  ', initial_mode = "normal",
    layout_strategy = 'vertical', layout_config = { preview_height = 30 } }
end)

-- registers
vim.keymap.set('n', ';k', function()
  builtin.registers { initial_mode = "normal" }
end)

-- find files with names that contain cursor word
vim.keymap.set('n', ';sf', function()
  builtin.find_files({ initial_mode = "normal", find_command = { 'fd', vim.fn.expand('<cword>') } })
end)


-- Telescope oldfiles
vim.keymap.set('n', ';o', function()
  builtin.oldfiles { initial_mode = "normal", layout_strategy = 'vertical',
    layout_config = { preview_height = 28 } }
end)

-- find text in current buffer
vim.keymap.set('n', ';bf', function()
  builtin.current_buffer_fuzzy_find { layout_strategy = 'vertical',
    layout_config = { preview_height = 28 } }
end)

-- view keymaps
vim.keymap.set('n', ';m', function()
  builtin.keymaps {}
end)

-- pick color scheme
vim.keymap.set('n', ';cs', function()
  builtin.colorscheme {}
end)

-- command history
vim.keymap.set('n', ';h', function()
  builtin.command_history {}
end)

-- neoclip
vim.keymap.set("n", ";n", function()
  telescope.extensions.neoclip.default()
end)
