local M = {}

local VENV_DIRS = { ".venv", "venv" }

local poetry_environments = {}

local function interpreter_in(dir)
  if not dir or dir == "" then
    return nil
  end
  local path = dir .. "/bin/python"
  return vim.uv.fs_stat(path) and path or nil
end

local function venv_in_project(root)
  for _, name in ipairs(VENV_DIRS) do
    local path = interpreter_in(root .. "/" .. name)
    if path then
      return path
    end
  end
end

local function declares_poetry(root)
  local pyproject = root .. "/pyproject.toml"
  if not vim.uv.fs_stat(pyproject) then
    return false
  end

  for line in io.lines(pyproject) do
    if line:find("^%s*%[tool%.poetry") then
      return true
    end
  end
  return false
end

-- uv and `python -m venv` both keep the environment in the project, so a file
-- check finds them. Only poetry can hide it somewhere else.
local function interpreter_for(root)
  return interpreter_in(vim.env.VIRTUAL_ENV)
    or (root and venv_in_project(root))
    or vim.fn.exepath("python3")
end

-- The client copies `settings` before `before_init` runs, so the interpreter
-- must arrive as a configuration change instead.
local function use_interpreter(client, path)
  client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
    python = { pythonPath = path },
  })
  client:notify("workspace/didChangeConfiguration", { settings = client.settings })
end

local function poetry_hides_environment(root)
  return root ~= nil
    and interpreter_in(vim.env.VIRTUAL_ENV) == nil
    and venv_in_project(root) == nil
    and vim.fn.executable("poetry") == 1
    and declares_poetry(root)
end

-- Asking poetry for its environment costs about half a second, so the server
-- starts on the fallback interpreter and swaps over once poetry answers.
local function ask_poetry(client, root)
  vim.system({ "poetry", "env", "info", "--executable" }, { cwd = root, text = true }, function(result)
    local path = vim.trim(result.stdout or "")
    if result.code ~= 0 or path == "" then
      return
    end

    vim.schedule(function()
      poetry_environments[root] = path
      if not client:is_stopped() then
        use_interpreter(client, path)
      end
    end)
  end)
end

function M.on_init(client)
  local root = client.root_dir
  use_interpreter(client, interpreter_for(root))

  if not poetry_hides_environment(root) then
    return
  end

  if poetry_environments[root] then
    use_interpreter(client, poetry_environments[root])
  else
    ask_poetry(client, root)
  end
end

return M
