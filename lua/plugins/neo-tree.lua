local SHOW_ALL_FILES = {
  hide_dotfiles = false,
  hide_gitignored = false,
  hide_ignored = false,
  hide_hidden = false,
}

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = false,

  keys = {
    { "<leader>E", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
    { "<leader>e", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in explorer" },
  },

  ---@module 'neo-tree'
  ---@type neotree.Config
  opts = {
    filesystem = {
      filtered_items = SHOW_ALL_FILES,
    },
  },
}
