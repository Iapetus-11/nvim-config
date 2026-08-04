local FILTERED_ITEMS = {
  hide_dotfiles = false,
  hide_gitignored = false,
  hide_ignored = false,
  hide_hidden = false,
  never_show = { ".git", ".idea" },
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
      -- Nvim reclaims only the buffer it started with, so this placeholder
      -- would sit in the tabline all session. The first file opened reuses it.
      vim.bo.buflisted = false
      require("neo-tree.command").execute({ action = "show", dir = dir })
    end,
  })
end

local function sidebar_source()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local source = vim.b[vim.api.nvim_win_get_buf(win)].neo_tree_source
    if source then
      return source
    end
  end
end

-- Switching sources in-place is broken upstream: the reused window never
-- gains focus, and showing the git view runs `git status`, whose event
-- prompts a filesystem rescan that steals the window back. Closing first
-- avoids both: a windowless source only marks itself dirty, and freshly
-- created windows are focused.
local function show(source, args)
  if sidebar_source() ~= source then
    vim.cmd("Neotree close")
  end
  require("neo-tree.command").execute(vim.tbl_extend("keep", { source = source, action = "focus" }, args or {}))
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
    {
      "<leader>e",
      function()
        show("filesystem", { reveal = true })
      end,
      desc = "Reveal current file in explorer",
    },
    {
      "<leader>g",
      function()
        show("git_status")
      end,
      desc = "Git changes",
    },
  },

  ---@module 'neo-tree'
  ---@type neotree.Config
  opts = {
    sources = { "filesystem", "git_status" },

    filesystem = {
      filtered_items = FILTERED_ITEMS,
      use_libuv_file_watcher = true,
    },

    git_status = {
      group_empty_dirs = true,
    },

    window = {
      mappings = {
    	-- Space is the leader
        ["<space>"] = "none",
      },
    },
  },

  config = function(_, opts)
    local git = require("neo-tree.git")

    -- Skip ignored files for a speed boost
    local status = git.status
    git.status = function(path, base, bubble, status_opts)
      return status(path, base, bubble, vim.tbl_extend("force", status_opts or {}, { ignored = "matching" }))
    end

    require("neo-tree").setup(opts)
  end,
}
