local common = require("modules.theme.sync.common")
local palette = require("modules.theme.palette")

local M = {}

function M.color_lines(colors)
  local palette_values = {
    fg = colors.fg,
    accent = colors.accent,
    border = colors.border,
    selection = colors.selection,
    ok = colors.ok,
    warn = colors.warn,
    err = colors.error,
  }
  local sections = {
    filekinds = {
      { "normal", "fg" }, { "directory", "accent" }, { "symlink", "border" }, { "pipe", "selection" },
      { "block_device", "err" }, { "char_device", "err" }, { "socket", "selection" }, { "special", "accent" },
      { "executable", "ok" }, { "mount_point", "border" },
    },
    perms = {
      { "user_read", "fg" }, { "user_write", "warn" }, { "user_execute_file", "ok" },
      { "user_execute_other", "ok" }, { "group_read", "fg" }, { "group_write", "warn" },
      { "group_execute", "ok" }, { "other_read", "selection" }, { "other_write", "warn" },
      { "other_execute", "ok" }, { "special_user_file", "accent" }, { "special_other", "selection" },
      { "attribute", "selection" },
    },
    size = {
      { "major", "selection" }, { "minor", "border" }, { "number_byte", "fg" }, { "number_kilo", "fg" },
      { "number_mega", "accent" }, { "number_giga", "accent" }, { "number_huge", "border" },
      { "unit_byte", "selection" }, { "unit_kilo", "accent" }, { "unit_mega", "accent" },
      { "unit_giga", "accent" }, { "unit_huge", "border" },
    },
    users = {
      { "user_you", "fg" }, { "user_root", "err" }, { "user_other", "accent" },
      { "group_yours", "fg" }, { "group_other", "selection" }, { "group_root", "err" },
    },
    links = { { "normal", "border" }, { "multi_link_file", "border" } },
    git = {
      { "new", "ok" }, { "modified", "warn" }, { "deleted", "err" }, { "renamed", "border" },
      { "typechange", "accent" }, { "ignored", "selection" }, { "conflicted", "err" },
    },
    git_repo = {
      { "branch_main", "fg" }, { "branch_other", "accent" }, { "git_clean", "ok" }, { "git_dirty", "err" },
    },
    security_context = {
      { "colon", "selection" }, { "user", "fg" }, { "role", "accent" }, { "typ", "selection" },
      { "range", "accent" },
    },
    file_type = {
      { "image", "warn" }, { "video", "err" }, { "music", "ok" }, { "lossless", "border" },
      { "crypto", "selection" }, { "document", "fg" }, { "compressed", "accent" }, { "temp", "err" },
      { "compiled", "border" }, { "build", "selection" }, { "source", "accent" },
    },
  }
  local order = { "filekinds", "perms", "size", "users", "links", "git", "git_repo", "security_context", "file_type" }
  local lines = { "colourful: true" }

  for _, section in ipairs(order) do
    table.insert(lines, "")
    table.insert(lines, section .. ":")
    for _, item in ipairs(sections[section]) do
      table.insert(lines, string.format("  %s: { foreground: \"%s\" }", item[1], palette_values[item[2]]))
    end
  end

  vim.list_extend(lines, {
    "",
    "punctuation: { foreground: \"" .. palette_values.selection .. "\" }",
    "date: { foreground: \"" .. palette_values.warn .. "\" }",
    "inode: { foreground: \"" .. palette_values.selection .. "\" }",
    "blocks: { foreground: \"" .. palette_values.selection .. "\" }",
    "header: { foreground: \"" .. palette_values.fg .. "\" }",
    "octal: { foreground: \"" .. palette_values.border .. "\" }",
    "flags: { foreground: \"" .. palette_values.accent .. "\" }",
    "",
    "symlink_path: { foreground: \"" .. palette_values.border .. "\" }",
    "control_char: { foreground: \"" .. palette_values.border .. "\" }",
    "broken_symlink: { foreground: \"" .. palette_values.err .. "\" }",
    "broken_path_overlay: { foreground: \"" .. palette_values.selection .. "\" }",
  })

  return lines
end

function M.sync(theme, ctx)
  local item = ctx.current_theme(theme)
  local mode = ctx.theme_mode(item, vim.o.background)
  local colors = palette.build(mode)
  local target = vim.fn.expand("~/.config/eza/theme.yml")
  local ok_write = pcall(common.write_lines, target, M.color_lines(colors))
  if not ok_write then
    vim.notify("eza theme sync failed: " .. target, vim.log.levels.WARN)
  end
end

return M
