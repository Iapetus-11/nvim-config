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
  return vim.iter(vim.api.nvim_tabpage_list_wins(0))
    :map(function(win)
      return vim.b[vim.api.nvim_win_get_buf(win)].neo_tree_source
    end)
    :next()
end

-- In-place source switches are broken upstream: the reused window is never
-- focused, and a git-triggered filesystem rescan steals the window back.
-- Reopening from closed avoids both.
local function show(args)
  if sidebar_source() ~= args.source then
    require("neo-tree.command").execute({ action = "close" })
  end
  require("neo-tree.command").execute(args)
end

local function toggle()
  if sidebar_source() then
    require("neo-tree.command").execute({ action = "close" })
  else
    show({ source = "filesystem" })
  end
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
    { "<leader>E", toggle, desc = "Toggle file explorer" },
    {
      "<leader>e",
      function()
        show({ source = "filesystem", reveal = true })
      end,
      desc = "Reveal current file in explorer",
    },
    {
      "<leader>g",
      function()
        show({ source = "git_status" })
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

    event_handlers = {
      -- The git watcher only sees the .git directory, so working-tree edits
      -- made outside Nvim leave the view stale until it is focused again.
      {
        event = "neo_tree_buffer_enter",
        id = "refresh-git-on-focus",
        handler = function()
          if vim.b.neo_tree_source == "git_status" then
            require("neo-tree.sources.git_status").refresh()
          end
        end,
      },

      -- The git view's status command enumerates every ignored file, which can
      -- be extremely slow.
      {
        event = "before_git_status",
        id = "ignored-dirs-only",
        handler = function(args)
          if not vim.tbl_contains(args.status_args, "--untracked-files=all") then
            return
          end
          for i, arg in ipairs(args.status_args) do
            if vim.startswith(arg, "--ignored") then
              args.status_args[i] = "--ignored=matching"
              return
            end
          end
          vim.notify("Expected neo-tree to pass --ignored; git status may be slow", vim.log.levels.WARN)
        end,
      },
    },
  },
}
