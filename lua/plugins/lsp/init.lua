local utils = require("utils")

-- Per-server settings live in lsp/<server>.lua at the config root; Neovim
-- merges those files on its own. This list decides what mason installs and
-- which servers actually start.
local SERVERS = {
  "lua_ls",
  "ruff",
  "basedpyright",
  "html",
  "bashls",
  "vtsls",
  "vue_ls",
  "eslint",
  "rust_analyzer",
}

-- vue_ls needs vtsls on .vue buffers too
local VTSLS_FILETYPES = {
  "javascript",
  "javascriptreact",
  "javascript.jsx",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "vue",
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
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
    "antosha417/nvim-lsp-file-operations",
  },

  keys = {
    { "<Leader>?", vim.diagnostic.open_float, desc = "Show line diagnostic" },
    { "<leader>uh", toggle_inlay_hints, desc = "Toggle inlay hints" },
  },

  config = function()
    require("plugins.lsp.keymaps")

    vim.diagnostic.config({
      virtual_text = false,
      virtual_lines = { current_line = true },
      signs = { text = utils.diagnostic_icons },
      float = { source = "if_many", focusable = false },
    })
    require("patches.diagnostic-virtual-lines-crash")

    -- Override nvim-lspconfig's lsp/vtsls.lua
    vim.lsp.config("vtsls", { filetypes = VTSLS_FILETYPES })

    vim.lsp.config("*", {
      capabilities = require("lsp-file-operations").default_capabilities(),
    })

    -- `automatic_enable` defaults to every server mason has installed, which
    -- starts leftovers from an earlier config alongside their replacement.
    -- Passing the list makes it authoritative in both directions.
    require("mason-lspconfig").setup({
      ensure_installed = SERVERS,
      automatic_enable = SERVERS,
    })
  end,
}
