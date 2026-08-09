return {
  "antosha417/nvim-lsp-file-operations",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-neo-tree/neo-tree.nvim",
  },

  lazy = true,

  opts = {
    operations = {
      -- neo-tree has no before-create/delete events
      willCreateFiles = false,
      willDeleteFiles = false,
    },
  },

  config = function(_, opts)
    require("lsp-file-operations").setup(opts)
    require("plugins.lsp.vue-rename").setup()
  end,
}
