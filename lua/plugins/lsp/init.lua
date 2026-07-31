local utils = require("utils")

-- Per-server settings live in lsp/<server>.lua at the config root; Neovim
-- merges those files on its own. This list only drives mason.
local SERVERS = {
  "lua_ls",
  "ruff",
  "pyright",
  "html",
  "bashls",
  "vtsls",
  "vue_ls",
  "eslint",
  "rust_analyzer",
}

local function toggle_inlay_hints()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
end

return {
  "neovim/nvim-lspconfig",

  cmd = { "LspStart", "LspStop", "LspRestart", "LspLog" },
  event = { "BufReadPre", "BufNewFile" },

  dependencies = {
    "folke/neoconf.nvim",
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
  },

  keys = {
    { "<Leader>?", vim.diagnostic.open_float, desc = "Show line diagnostic" },
    { "<leader>uh", toggle_inlay_hints, desc = "Toggle inlay hints" },
  },

  config = function()
    require("neoconf").setup()

    require("plugins.lsp.keymaps")

    vim.diagnostic.config({
      virtual_text = false,
      virtual_lines = { current_line = true },
      signs = { text = utils.diagnostic_icons },
      float = { source = "if_many", focusable = false },
    })

    -- ensure_installed installs the servers; automatic enable starts them.
    require("mason-lspconfig").setup({
      ensure_installed = SERVERS,
    })
  end,
}
