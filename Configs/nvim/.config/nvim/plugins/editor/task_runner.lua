local M = {}

local last_task = nil
local state_file = vim.fn.stdpath("data") .. "/task_runner_last.json"

local function root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] then
    return out[1]
  end
  return vim.fn.getcwd()
end

local function has_file(name)
  return vim.fn.findfile(name, root() .. ";") ~= ""
end

local function save_last_task(task)
  last_task = task
  local ok, encoded = pcall(vim.json.encode, { label = task.label, cmd = task.cmd, cwd = task.cwd })
  if ok then
    vim.fn.writefile({ encoded }, state_file)
  end
end

local function load_last_task()
  if last_task then return end
  if vim.fn.filereadable(state_file) == 0 then return end
  local lines = vim.fn.readfile(state_file)
  if #lines == 0 then return end
  local ok, decoded = pcall(vim.json.decode, lines[1])
  if ok and type(decoded) == "table" and decoded.cmd then
    last_task = decoded
  end
end

local function parse_errors_to_qflist(bufnr, task)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local items = {}

  for _, line in ipairs(lines) do
    local file, lnum, col, text = line:match("^([^:]+):(%d+):(%d+):%s*(.+)$")
    if not file then
      file, lnum, text = line:match("^([^:]+):(%d+):%s*(.+)$")
      col = nil
    end
    if file and lnum and vim.fn.filereadable(file) == 1 then
      items[#items + 1] = {
        filename = file,
        lnum = tonumber(lnum),
        col = col and tonumber(col) or 0,
        text = text or "",
      }
    end
  end

  if #items > 0 then
    vim.fn.setqflist({}, " ", { title = "Task: " .. (task.label or ""), items = items })
    vim.notify(string.format("Task finished: %d errors parsed", #items), vim.log.levels.WARN)
  end
end

local function run_task(task)
  save_last_task(task)
  vim.cmd("botright 15split")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.fn.termopen(task.cmd, {
    cwd = task.cwd or root(),
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 and vim.api.nvim_buf_is_valid(bufnr) then
          parse_errors_to_qflist(bufnr, task)
        elseif code == 0 then
          vim.notify("Task finished: " .. (task.label or ""), vim.log.levels.INFO)
        end
      end)
    end,
  })
  vim.cmd("startinsert")
end

function M.tasks()
  load_last_task()
  local tasks = {}
  local cwd = root()
  if has_file("package.json") then
    tasks[#tasks + 1] = { label = "npm test", cmd = { "npm", "test" }, cwd = cwd }
    tasks[#tasks + 1] = { label = "npm run lint", cmd = { "npm", "run", "lint" }, cwd = cwd }
    tasks[#tasks + 1] = { label = "npm run build", cmd = { "npm", "run", "build" }, cwd = cwd }
  end
  if has_file("pom.xml") then
    tasks[#tasks + 1] = { label = "mvn test", cmd = { "mvn", "test" }, cwd = cwd }
    tasks[#tasks + 1] = { label = "mvn verify", cmd = { "mvn", "verify" }, cwd = cwd }
  end
  if has_file("gradlew") then
    tasks[#tasks + 1] = { label = "./gradlew test", cmd = { "./gradlew", "test" }, cwd = cwd }
  elseif has_file("build.gradle") or has_file("build.gradle.kts") then
    tasks[#tasks + 1] = { label = "gradle test", cmd = { "gradle", "test" }, cwd = cwd }
  end
  if has_file("sfdx-project.json") then
    tasks[#tasks + 1] = { label = "sf apex test run", cmd = { "sf", "apex", "test", "run" }, cwd = cwd }
  end
  if has_file("docker-compose.yml") or has_file("docker-compose.yaml") or has_file("compose.yml") or has_file("compose.yaml") then
    tasks[#tasks + 1] = { label = "docker compose ps", cmd = { "docker", "compose", "ps" }, cwd = cwd }
    tasks[#tasks + 1] = { label = "docker compose up", cmd = { "docker", "compose", "up" }, cwd = cwd }
  end
  if last_task then
    table.insert(tasks, 1, { label = "Run last: " .. last_task.label, cmd = last_task.cmd, cwd = last_task.cwd })
  end
  return tasks
end

function M.select()
  local tasks = M.tasks()
  if #tasks == 0 then
    vim.notify("No project tasks detected", vim.log.levels.INFO)
    return
  end
  vim.ui.select(tasks, {
    prompt = "Task Runner",
    format_item = function(item) return item.label end,
  }, function(task)
    if task then run_task(task) end
  end)
end

function M.run_last()
  load_last_task()
  if not last_task then
    vim.notify("No task has run yet", vim.log.levels.INFO)
    return
  end
  run_task(last_task)
end

return M
