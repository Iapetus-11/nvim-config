return {
  "nvim-treesitter/nvim-treesitter-context",

  opts = {
    max_lines = 3,
    separator = "─",
    multiline_threshold = 1,
  },

  config = function(_, opts)
    require("treesitter-context").setup(opts)
    vim.api.nvim_set_hl(0, "TreesitterContextSeparator", { link = "WinSeparator" })
    vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { link = "LineNr" })
  end,
}
