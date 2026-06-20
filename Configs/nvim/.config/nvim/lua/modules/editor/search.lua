local core = require("modules.editor.search.core")
local files = require("modules.editor.search.files")
local grep = require("modules.editor.search.grep")
local buffers = require("modules.editor.search.buffers")
local misc = require("modules.editor.search.misc")
local git = require("modules.editor.search.git")

local M = {}

M.root = core.root

M.open_explorer = files.open_explorer
M.find_files = files.find_files
M.git_files = files.git_files
M.recent_files = files.recent_files
M.open_terminal = files.open_terminal

M.grep = grep.grep
M.grep_picker = grep.grep_picker
M.grep_word = grep.grep_word

M.buffers = buffers.buffers
M.delete_buffer = buffers.delete_buffer
M.delete_other_buffers = buffers.delete_other_buffers

M.registers = misc.registers
M.command_history = misc.command_history
M.commands = misc.commands
M.diagnostics = misc.diagnostics
M.help = misc.help
M.keymaps = misc.keymaps
M.loclist = misc.loclist
M.qflist = misc.qflist
M.marks = misc.marks
M.notifications = misc.notifications
M.undo_history = misc.undo_history

M.lazygit = git.lazygit
M.git_log = git.git_log
M.git_blame_line = git.git_blame_line
M.git_file_history = git.git_file_history
M.git_browse = git.git_browse

return M
