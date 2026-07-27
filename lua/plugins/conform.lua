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

local prettier_config_cache = {}
local function prettier_has_config(ctx)
  local dir = vim.fs.dirname(ctx.filename)
  if prettier_config_cache[dir] == nil then
    vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
    prettier_config_cache[dir] = vim.v.shell_error == 0
  end
  return prettier_config_cache[dir]
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

    formatters = {
      prettier = {
        condition = function(_, ctx)
          return prettier_has_config(ctx)
        end,
      },
    },

    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "never",
    },
  },
}
