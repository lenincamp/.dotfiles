local M = {}

local build_running = false
local build_notified = false
local build_callbacks = {}

local function plugin_dir()
  return vim.fn.stdpath("data") .. "/site/pack/core/opt/avante.nvim"
end

function M.templates_ready(dir)
  dir = dir or plugin_dir()
  local templates_lib = dir .. "/lua/avante_templates.so"

  if vim.fn.isdirectory(dir) == 0 then
    return false
  end

  return package.loaded.avante_templates ~= nil
    or package.searchpath("avante_templates", package.cpath) ~= nil
    or vim.fn.filereadable(templates_lib) == 1
end

local function run_async(dir, command, on_done)
  vim.system(command, { cwd = dir, text = true }, function(result)
    vim.schedule(function()
      on_done(result and result.code == 0, result or {})
    end)
  end)
end

local function resolve_build_error(result, fallback)
  local stderr = result and vim.trim(result.stderr or "") or ""
  local stdout = result and vim.trim(result.stdout or "") or ""
  if stderr ~= "" then
    return stderr
  end
  if stdout ~= "" then
    return stdout
  end
  return fallback or "build failed"
end

local function build_from_source_on_macos_async(dir, on_done)
  if vim.fn.executable("cargo") ~= 1 then
    on_done(false, { stderr = "cargo not available" })
    return
  end

  run_async(dir, {
    "sh",
    "-c",
    table.concat({
      "cargo build --release --features=luajit -p avante-tokenizers -p avante-templates -p avante-repo-map -p avante-html2md",
      "cp target/release/libavante_tokenizers.dylib lua/avante_tokenizers.so",
      "cp target/release/libavante_templates.dylib lua/avante_templates.so",
      "cp target/release/libavante_repo_map.dylib lua/avante_repo_map.so",
      "cp target/release/libavante_html2md.dylib lua/avante_html2md.so",
    }, " && "),
  }, on_done)
end

local function flush_build_callbacks(ok)
  local callbacks = build_callbacks
  build_callbacks = {}
  for _, cb in ipairs(callbacks) do
    pcall(cb, ok)
  end
end

function M.ensure_ready(on_ready)
  local dir = plugin_dir()
  local is_macos = vim.uv.os_uname().sysname == "Darwin"

  if vim.fn.isdirectory(dir) == 0 then
    return false
  end

  if M.templates_ready(dir) then
    return true
  end

  if type(on_ready) == "function" then
    build_callbacks[#build_callbacks + 1] = on_ready
  end

  if build_running then
    return false
  end

  build_running = true
  if not build_notified then
    build_notified = true
    vim.notify("Preparing Avante in background...", vim.log.levels.INFO)
  end

  local function finish_build(ok, err_msg)
    build_running = false
    build_notified = false

    local ready = ok and M.templates_ready(dir)
    if not ready then
      vim.notify("avante.nvim build failed: " .. tostring(err_msg or "build failed"), vim.log.levels.ERROR)
    end

    flush_build_callbacks(ready)
  end

  local function run_macos_fallback(make_result)
    if not is_macos then
      finish_build(false, resolve_build_error(make_result, "make failed"))
      return
    end

    build_from_source_on_macos_async(dir, function(ok, result)
      if ok and M.templates_ready(dir) then
        finish_build(true)
        return
      end
      finish_build(false, resolve_build_error(result, "build failed"))
    end)
  end

  if vim.fn.executable("make") == 1 then
    run_async(dir, { "make" }, function(ok, result)
      if ok and M.templates_ready(dir) then
        finish_build(true)
        return
      end
      run_macos_fallback(result)
    end)
    return false
  end

  if is_macos then
    run_macos_fallback({ stderr = "make not available" })
    return false
  end

  finish_build(false, "make is not available in PATH")
  return false
end

return M
