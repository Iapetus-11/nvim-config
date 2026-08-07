return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-neotest/neotest-python",
  },

  keys = {
    {
      "<leader>Tt",
      function()
        require("neotest").run.run()
      end,
      desc = "Run nearest test",
    },
    {
      "<leader>Tf",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      desc = "Run test file",
    },
    {
      "<leader>Tl",
      function()
        require("neotest").run.run_last()
      end,
      desc = "Run last test",
    },
    {
      "<leader>Ts",
      function()
        require("neotest").summary.toggle()
      end,
      desc = "Toggle test summary",
    },
    {
      "<leader>To",
      function()
        require("neotest").output.open({ enter = true, auto_close = true })
      end,
      desc = "Show test output",
    },
  },

  opts = function()
    return {
      adapters = {
        require("neotest-python")({ runner = "pytest" }),
      },
    }
  end,
}
