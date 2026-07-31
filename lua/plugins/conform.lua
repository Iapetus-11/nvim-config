local prettier_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "vue",
  "css",
  "scss",
  "less",
  "html",
  "json",
  "jsonc",
  "yaml",
  "markdown",
  "markdown.mdx",
  "graphql",
  "handlebars",
}

local formatters_by_ft = {}
for _, ft in ipairs(prettier_filetypes) do
  formatters_by_ft[ft] = { "prettier" }
end

return {
  "stevearc/conform.nvim",

  event = { "BufWritePre" },
  cmd = { "ConformInfo" },

  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_format = "never" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },

  opts = {
    formatters_by_ft = formatters_by_ft,

    -- Prettier only runs in projects that declare a prettier config; conform
    -- finds it with file checks, including the package.json `prettier` key.
    formatters = {
      prettier = { require_cwd = true },
    },

    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "never",
    },
  },
}
