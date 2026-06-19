local M = {}

local last_task = nil

local function root()
  return require("modules.editor.search").root()
end

local function has_file(name)
  return vim.fn.findfile(name, root() .. ";") ~= ""
end

local function run_task(task)
  last_task = task
  vim.cmd("botright 15split")
  vim.fn.termopen(task.cmd, { cwd = task.cwd or root() })
  vim.cmd("startinsert")
end

function M.tasks()
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
  if vim.fn.executable("lazygit") == 1 then
    tasks[#tasks + 1] = { label = "lazygit", cmd = { "lazygit" }, cwd = cwd }
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
  require("modules.editor.picker").select_items(tasks, {
    prompt = "Task Runner",
    scope = "project",
    search_threshold = 0,
    format_item = function(item) return item.label end,
  }, function(task)
    if task then run_task(task) end
  end)
end

function M.run_last()
  if not last_task then
    vim.notify("No task has run yet", vim.log.levels.INFO)
    return
  end
  run_task(last_task)
end

return M
