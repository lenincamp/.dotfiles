local M = {}

local AVANTE_KEYS = {
  { mode = { "n", "x" }, lhs = "<leader>aa" },
  { mode = "n", lhs = "<leader>at" },
  { mode = { "n", "x" }, lhs = "<leader>ae" },
  { mode = "n", lhs = "<leader>an" },
  { mode = "n", lhs = "<leader>ah" },
  { mode = "n", lhs = "<leader>aS" },
  { mode = "n", lhs = "<leader>ar" },
  { mode = "n", lhs = "<leader>af" },
  { mode = "n", lhs = "<leader>a?" },
  { mode = "n", lhs = "<leader>aM" },
  { mode = "n", lhs = "<leader>aP" },
  { mode = "n", lhs = "<leader>aC" },
  { mode = "n", lhs = "<leader>aR" },
  { mode = "n", lhs = "<leader>ac" },
  { mode = "n", lhs = "<leader>aB" },
  { mode = "n", lhs = "<leader>az" },
}

function M.setup(load_cfg_once)
  if type(load_cfg_once) ~= "function" then
    return
  end

  local last_pending_notice_ms = 0

  local function loaded_state(name)
    return package.loaded[name] ~= nil
  end

  local function state_line(prefix)
    return prefix
      .. " minuet=" .. tostring(loaded_state("minuet"))
      .. " avante=" .. tostring(loaded_state("avante"))
      .. " blink=" .. tostring(loaded_state("blink.cmp"))
  end

  local function report_path()
    local dir = vim.fn.stdpath("state") .. "/reports"
    vim.fn.mkdir(dir, "p")
    return dir .. "/ai_fluency_diag_" .. os.date("%Y%m%d_%H%M%S") .. ".log"
  end

  local function load_avante_stack()
    return load_cfg_once("avante")
  end

  local function run_ai_first_use_diag(mode)
    local lines = {}
    local function add(line)
      lines[#lines + 1] = line
    end

    add("AI_FLUENCY_DIAG_START")
    add("timestamp=" .. os.date("%Y-%m-%dT%H:%M:%S"))
    add(state_line("startup_loaded"))

    local warmup_wait_ms = 1800
    vim.wait(warmup_wait_ms)
    add(state_line("after_" .. warmup_wait_ms .. "ms"))

    local load_start = vim.uv.hrtime()
    local load_ok = load_avante_stack()
    local load_ms = (vim.uv.hrtime() - load_start) / 1e6
    add(string.format("avante_load_call_ms=%.1f ok=%s", load_ms, tostring(load_ok)))
    add(state_line("after_AvanteLoad"))

    if mode == "full" then
      local mapping = vim.fn.maparg("<leader>aa", "n", false, true)
      local has_callback = type(mapping) == "table" and type(mapping.callback) == "function"
      add("aa_map_has_callback=" .. tostring(has_callback))
      if has_callback then
        local key_start = vim.uv.hrtime()
        mapping.callback()
        vim.wait(350)
        local key_ms = (vim.uv.hrtime() - key_start) / 1e6
        add(string.format("aa_callback_elapsed_ms=%.1f", key_ms))
        add(state_line("after_keypath"))
      end
    end

    add("AI_FLUENCY_DIAG_END")

    local path = report_path()
    local ok, err = pcall(vim.fn.writefile, lines, path)
    if ok then
      vim.notify("AI fluency report saved: " .. path, vim.log.levels.INFO)
    else
      vim.notify("AI fluency report failed: " .. tostring(err), vim.log.levels.WARN)
      return nil
    end

    return path
  end

  local function replay_lhs(lhs)
    if not load_avante_stack() then
      local now_ms = vim.uv.now()
      if now_ms - last_pending_notice_ms > 1800 then
        last_pending_notice_ms = now_ms
        vim.notify("Avante is warming up in background. Retry in a moment.", vim.log.levels.INFO)
      end
      return
    end

    vim.schedule(function()
      local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
      vim.api.nvim_feedkeys(keys, "m", false)
    end)
  end

  for _, mapping in ipairs(AVANTE_KEYS) do
    vim.keymap.set(mapping.mode, mapping.lhs, function()
      replay_lhs(mapping.lhs)
    end, {
      silent = true,
      desc = "Avante: load on demand",
    })
  end

  vim.api.nvim_create_user_command("AvanteLoad", function()
    load_avante_stack()
  end, { desc = "Load Avante configuration" })

  vim.api.nvim_create_user_command("AIFirstUseDiag", function(opts)
    local mode = vim.trim(opts.args or "")
    if mode ~= "" and mode ~= "full" then
      vim.notify("AIFirstUseDiag accepts only 'full' or no args", vim.log.levels.WARN)
      return
    end

    run_ai_first_use_diag(mode)
  end, {
    nargs = "?",
    complete = function()
      return { "full" }
    end,
    desc = "Measure first-use AI fluency (use :AIFirstUseDiag full for keypath)",
  })
end

return M
