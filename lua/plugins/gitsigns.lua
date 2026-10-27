return {
  "lewis6991/gitsigns.nvim",

  event = { "BufReadPre", "BufNewFile" },

  keys = {
    {
      "]h",
      function()
        require("gitsigns").nav_hunk("next", { target = "all" })
      end,
      desc = "Next Git hunk",
    },
    {
      "[h",
      function()
        require("gitsigns").nav_hunk("prev", { target = "all" })
      end,
      desc = "Previous Git hunk",
    },
  },

  opts = {},
}
