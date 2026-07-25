return {
  -- Loaded eagerly so Mason's bin directory is prepended to PATH before any
  -- server is started. Servers installed here are otherwise invisible to
  -- vim.lsp.enable(), which refuses to launch a non-executable cmd.
  "mason-org/mason.nvim",
  lazy = false,
  priority = 100,
  opts = {},
}
