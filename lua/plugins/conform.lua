local formatters_by_ft = {
  rust = { "rustfmt" },
  ruby = { lsp_format = "fallback" },
  c = { "clang_format" },
  python = { "ruff_format", "autopep8", stop_after_first = true },
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
  { "rust", "ruby" },
  vim.tbl_filter(function(file_type)
    return file_type ~= "graphql"
  end, prettier_filetypes)
)

-- Ruff format is Black style and cannot match other styles such as PyCharm's,
-- so it only runs in projects whose nearest ruff config has a format section.
local function has_ruff_format_config(ctx)
  local config = vim.fs.find(
    { ".ruff.toml", "ruff.toml", "pyproject.toml" },
    { path = ctx.dirname, upward = true }
  )[1]
  if not config then
    return false
  end
  local section = vim.fs.basename(config) == "pyproject.toml" and "[tool.ruff.format]" or "[format]"
  return vim.list_contains(vim.fn.readfile(config), section)
end

return {
  "stevearc/conform.nvim",

  event = { "BufWritePre" },
  cmd = { "ConformInfo" },

  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true })
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
      -- PyCharm does not rewrite lambdas; the rest are autopep8's defaults.
      autopep8 = {
        prepend_args = { "--max-line-length", "120", "--ignore", "E226,E24,W50,W690,E731" },
      },
      ruff_format = {
        condition = function(_, ctx)
          return has_ruff_format_config(ctx)
        end,
      },
    },

    format_on_save = function(bufnr)
      local filetype = vim.bo[bufnr].filetype

      if vim.tbl_contains(format_on_save_filetypes, filetype) then
        return { timeout_ms = 2000 }
      end
    end,
  },
}
