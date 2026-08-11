local SHOW_HIDDEN = { "--hidden" }

local NEVER_LIST = {
  "^%.git/",
  "/%.git/",
  "^target/",
  "/target/",
  "%.rs%.bk$",
}

return {
  "nvim-telescope/telescope.nvim",
  version = "0.2.*",

  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },

  cmd = "Telescope",

  keys = {
    { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Grep project" },
    { "<leader>,", "<cmd>Telescope buffers<cr>", desc = "Open buffers" },
    { "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
    { "<leader>sd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    { "<leader>sr", "<cmd>Telescope resume<cr>", desc = "Resume last picker" },
  },

  opts = {
    defaults = {
      file_ignore_patterns = NEVER_LIST,

      -- Open selections in a regular file window, not Neo-tree/terminals
      get_selection_window = function()
        local wins = vim.api.nvim_list_wins()
        table.insert(wins, 1, vim.api.nvim_get_current_win())
        for _, win in ipairs(wins) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].buftype == "" then
            return win
          end
        end
        return 0
      end,
    },

    pickers = {
      find_files = { hidden = true },
      live_grep = { additional_args = SHOW_HIDDEN },
      grep_string = { additional_args = SHOW_HIDDEN },
    },
  },

  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("fzf")
  end,
}
