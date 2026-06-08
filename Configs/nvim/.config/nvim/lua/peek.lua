-- Peek preview (floating window with chainable navigation)
-- Features:
--   • LSP-aware function/method detection via treesitter
--   • Chainable: gpd inside gpd works (peek_request on real buffer)
--   • Editable: <C-s> saves actual file, LSP runs inside preview
--   • Stack navigation: <BS> back, gpc close all, <CR> jump to file
-- ── Treesitter function detection ──────────────────────────────────────
local FN_TYPES = {
    -- JavaScript / TypeScript / TSX
    function_declaration = true,
    function_expression = true,
    arrow_function = true,
    method_definition = true,
    generator_function_declaration = true,
    -- Java / Kotlin
    method_declaration = true,
    constructor_declaration = true,
    function_body = false,
    -- Python
    function_definition = true,
    -- Lua
    local_function = true,
    -- Rust / Go / C / C++
    function_item = true,
    -- Generic fallbacks
    ["function"] = true,
    method = true
}

--- Find enclosing function node range using treesitter.
--- @param bufnr number
--- @param target_line number 0-indexed line
--- @param target_col number
--- @return number? start_line_0, number? end_line_0
local function fn_range_ts(bufnr, target_line, target_col)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok then
        return nil
    end
    local tree = parser:parse()[1]
    if not tree then
        return nil
    end

    local node = tree:root():named_descendant_for_range(target_line, target_col, target_line, target_col)

    while node do
        if FN_TYPES[node:type()] then
            local sr, _, er, _ = node:range()
            return sr, er
        end
        node = node:parent()
    end
    return nil
end

--- Find JDTLS method/constructor by name (for jdt:// buffers with missing source info).
--- @param bufnr number
--- @param method_name string
--- @return number? row, number? col
local function find_jdt_method(bufnr, method_name)
    local ok_q, query = pcall(vim.treesitter.query.parse, "java", [[
    (method_declaration      name: (identifier) @name)
    (constructor_declaration name: (identifier) @name)
  ]])
    if not ok_q then
        return nil
    end
    local ok_p, parser = pcall(vim.treesitter.get_parser, bufnr, "java")
    if not ok_p then
        return nil
    end
    local tree = parser:parse()[1]
    if not tree then
        return nil
    end
    for _, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
        if vim.treesitter.get_node_text(node, bufnr) == method_name then
            local row, col = node:range()
            return row, col
        end
    end
end

-- ── Peek stack & cleanup ──────────────────────────────────────────────

local peek_stack = {}

local function cleanup_keymaps(entry)
    for _, lhs in ipairs(entry.added_maps or {}) do
        pcall(vim.api.nvim_buf_del_keymap, entry.bufnr, "n", lhs)
    end
end

local function pop()
    if #peek_stack == 0 then
        return
    end
    local top = table.remove(peek_stack)
    cleanup_keymaps(top)
    pcall(vim.api.nvim_win_close, top.win, true)
    if #peek_stack > 0 then
        local prev = peek_stack[#peek_stack]
        if vim.api.nvim_win_is_valid(prev.win) then
            vim.api.nvim_set_current_win(prev.win)
        end
    end
end

local function close_all()
    local copy = vim.deepcopy(peek_stack)
    peek_stack = {}
    for _, entry in ipairs(copy) do
        cleanup_keymaps(entry)
        pcall(vim.api.nvim_win_close, entry.win, true)
    end
end

-- ── Main peek request handler ─────────────────────────────────────────

local function request(method)
    local clients = vim.lsp.get_clients({
        bufnr = 0
    })
    local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
    local params = vim.lsp.util.make_position_params(0, encoding)
    local word = vim.fn.expand("<cword>")

    vim.lsp.buf_request(0, method, params, function(_, result, ctx)
        if not result or vim.tbl_isempty(result) then
            vim.notify("No results", vim.log.levels.INFO)
            return
        end

        local loc = vim.islist(result) and result[1] or result
        local uri = loc.uri or loc.targetUri
        local range = loc.range or loc.targetSelectionRange or loc.targetRange
        if not uri or not range then
            return
        end

        local bufnr = vim.uri_to_bufnr(uri)
        vim.fn.bufload(bufnr)

        local tgt_line = range.start.line
        local tgt_col = range.start.character

        -- JDTLS fallback: find method by name when source unavailable
        if tgt_line == 0 and uri:match("^jdt://") and word ~= "" then
            local row, col = find_jdt_method(bufnr, word)
            if row then
                tgt_line, tgt_col = row, col
            end
        end

        -- Treesitter: full function body detection
        local fn_start, fn_end = fn_range_ts(bufnr, tgt_line, tgt_col)
        local scroll_top = fn_start and math.max(0, fn_start - 1) or math.max(0, tgt_line - 3)
        local fn_size = fn_end and (fn_end - scroll_top + 2) or 32

        -- Window sizing
        local max_h = math.floor(vim.o.lines * 0.65)
        local height = math.max(10, math.min(fn_size, max_h))
        local width = math.min(110, vim.o.columns - 8)

        -- Cascade offset per stack depth
        local depth = #peek_stack
        local row = 1 + depth
        local col = depth * 3

        -- Title bar
        local fname = vim.fn.fnamemodify(vim.uri_to_fname(uri), ":t")
        local depth_tag = depth > 0 and (" [" .. depth + 1 .. "] ") or " "
        local size_tag = fn_start and (fn_size .. "L") or ("~" .. fn_size .. "L")
        local hint = (fn_size > height) and " ↕" or ""
        local edit_tag = "  ✎ "
        local title = string.format(" %s%s%s%s%s", fname, depth_tag, size_tag, hint, edit_tag)

        -- Open floating window with REAL buffer
        local win = vim.api.nvim_open_win(bufnr, true, {
            relative = "cursor",
            row = row,
            col = col,
            width = width,
            height = height,
            border = "rounded",
            title = title,
            title_pos = "center"
        })

        vim.wo[win].wrap = false
        vim.wo[win].cursorline = true
        vim.wo[win].number = true
        vim.wo[win].signcolumn = "no"
        vim.wo[win].scrolloff = 3

        -- Scroll to function start, cursor on target
        vim.api.nvim_win_call(win, function()
            vim.fn.winrestview({
                topline = scroll_top + 1
            })
        end)
        pcall(vim.api.nvim_win_set_cursor, win, {tgt_line + 1, tgt_col})

        -- Buffer-local keymaps (cleaned on close)
        local added = {}
        local function bmap(lhs, rhs, desc)
            local existing = vim.fn.maparg(lhs, "n", false, true)
            if not (existing and existing.buffer == 1) then
                vim.keymap.set("n", lhs, rhs, {
                    buffer = bufnr,
                    nowait = true,
                    desc = desc
                })
                added[#added + 1] = lhs
            end
        end

        bmap("<BS>", pop, "Peek: back one level")
        bmap("q", pop, "Peek: close current")
        bmap("<Esc>", pop, "Peek: close current")

        bmap("<CR>", function()
            close_all()
            vim.lsp.util.show_document(loc, ctx.client_id, {
                focus = true
            })
        end, "Peek: jump to file")

        bmap("<C-Up>", function()
            vim.api.nvim_win_set_height(win, math.min(vim.api.nvim_win_get_height(win) + 5, max_h))
        end, "Peek: taller")
        bmap("<C-Down>", function()
            vim.api.nvim_win_set_height(win, math.max(vim.api.nvim_win_get_height(win) - 5, 5))
        end, "Peek: shorter")

        -- Push to stack
        local entry = {
            win = win,
            bufnr = bufnr,
            added_maps = added
        }
        table.insert(peek_stack, entry)

        -- Auto-cleanup on close
        vim.api.nvim_create_autocmd("WinClosed", {
            pattern = tostring(win),
            once = true,
            callback = function()
                cleanup_keymaps(entry)
                for i, p in ipairs(peek_stack) do
                    if p.win == win then
                        table.remove(peek_stack, i);
                        break
                    end
                end
            end
        })
    end)
end

-- ── References via Snacks picker ──────────────────────────────────────

local function references()
    local ok, Snacks = pcall(require, "snacks")
    if ok and Snacks.picker then
        Snacks.picker.lsp_references()
    else
        vim.lsp.buf.references()
    end
end

return {
    close_all = close_all,
    request = request,
    references = references
}
