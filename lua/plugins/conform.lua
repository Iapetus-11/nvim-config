-- Only run prettier in projects that actually ship a prettier config, so we
-- don't reformat (and blow up the diff of) files in repos that don't use it.
-- Delegating to prettier's own resolver handles every config variant plus the
-- package.json "prettier" key; memoized per-directory so it spawns at most once
-- per directory per session.
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
    -- Prettier for the web stack (filetype superset mirrors LazyVim's).
    formatters_by_ft = {
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      vue = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      less = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      ["markdown.mdx"] = { "prettier" },
      graphql = { "prettier" },
      handlebars = { "prettier" },
    },

    formatters = {
      -- conform runs the project-local prettier from node_modules when present,
      -- otherwise one on PATH (e.g. the Mason-installed one). Gated on the
      -- project having a prettier config.
      prettier = {
        condition = function(_, ctx)
          return prettier_has_config(ctx)
        end,
      },
    },

    -- Format on save, but never let the LSP format instead: prettier is the
    -- single source of truth for these filetypes.
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "never",
    },
  },
}
