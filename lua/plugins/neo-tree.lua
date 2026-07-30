local SHOW_ALL_FILES = {
  hide_dotfiles = false,
  hide_gitignored = false,
  hide_ignored = false,
  hide_hidden = false,
}

-- Neo-tree must get all directory buffers. Two problems prevent this. Netrw
-- loads after the config, so neo-tree cannot delete the netrw autocommands
-- that show directories. Neo-tree also replaces a directory buffer too late,
-- so `nvim <dir>` shows an empty window for a moment.
local function claim_directories()
  -- Load netrw now, then delete only its directory group. Netrw keeps the
  -- remote-file support.
  vim.cmd("packadd netrw")
  vim.cmd("silent! autocmd! FileExplorer")

  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    desc = "Open neo-tree for a directory argument without a visible flash",
    callback = function()
      local dir = vim.fn.argv(0) --[[@as string]]
      if vim.fn.argc(-1) ~= 1 or vim.fn.isdirectory(dir) ~= 1 then
        return
      end
      dir = vim.fn.fnamemodify(dir, ":p")
      local dir_buf = vim.api.nvim_get_current_buf()
      vim.cmd("enew")
      pcall(vim.api.nvim_buf_delete, dir_buf, { force = true })
      require("neo-tree.command").execute({ action = "show", dir = dir })
    end,
  })
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = false,
  init = claim_directories,

  keys = {
    { "<leader>E", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
    { "<leader>e", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in explorer" },
  },

  ---@module 'neo-tree'
  ---@type neotree.Config
  opts = {
    filesystem = {
      filtered_items = SHOW_ALL_FILES,
      use_libuv_file_watcher = true,
    },
  },
}
