local CONFIG_ROOT = vim.fs.normalize(vim.fn.stdpath("config"))

-- Alongside a `lua/` directory these mark a Neovim config or plugin repo. Every
-- published plugin ships `doc/`; not every one ships `plugin/`.
local NEOVIM_MARKERS = { "init.lua", "lazy-lock.json", "plugin", "doc" }

-- lazydev enables itself everywhere by default. Limit it to projects that really are Neovim Lua:
-- this config, or a plugin repo.
local function is_neovim_lua(root)
  if type(root) ~= "string" then
    return false
  end

  root = vim.fs.normalize(root)
  if root == CONFIG_ROOT then
    return true
  end

  if not vim.uv.fs_stat(root .. "/lua") then
    return false
  end

  return vim.iter(NEOVIM_MARKERS):any(function(marker)
    return vim.uv.fs_stat(root .. "/" .. marker) ~= nil
  end)
end

return {
  "folke/lazydev.nvim",

  ft = "lua",

  opts = {
    enabled = is_neovim_lua,

    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
  },
}
