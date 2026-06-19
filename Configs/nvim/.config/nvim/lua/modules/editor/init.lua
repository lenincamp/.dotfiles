local function dispatch(module_name, function_name)
  return function(...)
    local mod = require(module_name)
    local fn = mod[function_name]
    if type(fn) ~= "function" then
      vim.notify(string.format("Missing function %s in %s", function_name, module_name), vim.log.levels.ERROR)
      return
    end
    return fn(...)
  end
end

return {
  copy_path = dispatch("modules.editor.file_actions", "copy_path"),
  rename_file = dispatch("modules.editor.file_actions", "rename_file"),
  format = dispatch("modules.editor.file_actions", "format"),
  clear_search_highlights = dispatch("modules.editor.search_words", "clear_search_highlights"),
  enable_search_highlight_and_return = dispatch("modules.editor.search_words", "enable_search_highlight_and_return"),
  jump_word_reference = dispatch("modules.editor.search_words", "jump_word_reference"),
  duplicate_line_or_selection = dispatch("modules.editor.text_actions", "duplicate_line_or_selection"),
  line_completion = dispatch("modules.editor.text_actions", "line_completion"),
  call_hierarchy = dispatch("modules.editor.call_hierarchy", "open"),
  call_hierarchy_incoming = dispatch("modules.editor.call_hierarchy", "incoming"),
  call_hierarchy_outgoing = dispatch("modules.editor.call_hierarchy", "outgoing"),
  diff_jump_next = dispatch("modules.editor.diff_navigation", "diff_jump_next"),
  diff_jump_prev = dispatch("modules.editor.diff_navigation", "diff_jump_prev"),
  enable_diff_mode = dispatch("modules.editor.diff_mode", "enable_diff_mode"),
  disable_diff_mode = dispatch("modules.editor.diff_mode", "disable_diff_mode"),
  toggle_diff_mode = dispatch("modules.editor.diff_mode", "toggle_diff_mode"),
  toggle_diff_profile = dispatch("modules.editor.diff_mode", "toggle_diff_profile"),
  compare_with_clipboard = dispatch("modules.editor.clipboard_diff", "compare_with_clipboard"),
  open_quickfix_playbook = dispatch("modules.editor.file_actions", "open_quickfix_playbook"),
  toggle_zen_mode = dispatch("modules.ui.zen", "toggle_zen_mode"),
  cycle_zen_width = dispatch("modules.ui.zen", "cycle_zen_width"),
  git_compare_load_prompt = dispatch("modules.editor.git_actions", "git_compare_load_prompt"),
}
