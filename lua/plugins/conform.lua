local formatters_by_ft = {
  rust = { "rustfmt" },
  c = { "clang_format" },
  python = { "ruff_format" },
}

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
for _, file_type in ipairs(prettier_filetypes) do
  formatters_by_ft[file_type] = { "prettier" }
end

local format_on_save_filetypes = vim.list_extend(
  { "rust" },
  vim.tbl_filter(function(file_type)
    return file_type ~= "graphql"
  end, prettier_filetypes)
)

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

    format_on_save = function(bufnr)
      if vim.tbl_contains(format_on_save_filetypes, vim.bo[bufnr].filetype) then
        return { timeout_ms = 2000, lsp_format = "never" }
      end
    end,
  },
}
