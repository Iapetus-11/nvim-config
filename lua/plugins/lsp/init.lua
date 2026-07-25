return {
  "neovim/nvim-lspconfig",

  cmd = { "LspStart", "LspStop", "LspRestart", "LspLog" },
  -- Must fire *before* FileType: vim.lsp.enable() works by installing a
  -- FileType autocmd, so loading on BufEnter (which fires after) misses the
  -- first file opened and nothing attaches until you re-edit it.
  event = { "BufReadPre", "BufNewFile" },

  dependencies = {
    "folke/neoconf.nvim",
    "mason-org/mason-lspconfig.nvim",
  },

  keys = {
    {
      "<Leader>?",
      function()
        vim.diagnostic.config({
          float = {
            show_header = true,
            source = "if_many",
            border = "rounded",
            focusable = false,
          },
        })
        vim.diagnostic.open_float()
      end,
      desc = "Show line diagnostic",
    },
  },

  config = function()
    require("neoconf").setup()

    -- Define the virtual text diagnostic signs
    local signs = {
      Error = "",
      Warn = "",
      Hint = "󰌵",
      Info = "",
    }

    vim.diagnostic.config({
      virtual_text = {
        prefix = function(diagnostic)
          if diagnostic.severity == vim.diagnostic.severity.ERROR then
            return signs["Error"]
          elseif diagnostic.severity == vim.diagnostic.severity.WARN then
            return signs["Warn"]
          elseif diagnostic.severity == vim.diagnostic.severity.INFO then
            return signs["Hint"]
          else
            return signs["Info"]
          end
        end,
      },
    })
    -----------

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = {
            groupFileStatus = {
              ambiguity = "Any",
              duplicate = "Any",
              global = "Any",
              luadoc = "Any",
              redefined = "Any",
              ["type-check"] = "Any",
              unbalanced = "Any",

              await = "Opened",
              strict = "Opened",
              unused = "Opened",

              codestyle = "None",
              conventions = "None",
              strong = "None",
            },
            workspaceEvent = "OnChange",
            workspaceDelay = 200,
            workspaceRate = 100,
          },
          workspace = {
            checkThirdParty = false,
            -- Keep project files diagnostic-enabled while loading external API types.
            library = {
              vim.env.VIMRUNTIME,
              vim.fn.stdpath("data") .. "/lazy/luvit-meta/library",
              vim.fn.stdpath("data") .. "/lazy/snacks.nvim/lua",
            },
          },
        },
      },
    })
    vim.lsp.enable("lua_ls")

    -- ##### Python #####
    vim.lsp.config("ruff", {})
    vim.lsp.enable("ruff")

    -- Old pyright configuration
    -- vim.lsp.config("pyright", {
    --   settings = {
    --     pyright = {
    --       venv = ".venv",
    --     },
    --   },
    -- })
    -- vim.lsp.enable("pyright")
    -- #####

    vim.lsp.enable("html")
    -- vim.lsp.enable("clangd")

    vim.lsp.enable("bashls")

    vim.lsp.config("rust_analyzer", {
      settings = {
        ["rust-analyzer"] = {
          checkOnSave = true,
          check = {
            command = "clippy",
            workspace = true,
            -- features = "all",
          },
        },
      },
    })
    vim.lsp.enable("rust_analyzer")

    vim.lsp.config("jdtls", {})
    vim.lsp.enable("jdtls")

    require("lspconfig.ui.windows").default_options.border = "single"

    -- Install the servers enabled above. `automatic_enable = false` keeps the
    -- vim.lsp.enable() calls in this file the single source of truth for which
    -- servers actually run. rust_analyzer is omitted on purpose: it comes from
    -- rustup so it stays in lockstep with the toolchain.
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "ruff", "html", "bashls", "jdtls" },
      automatic_enable = false,
    })

    -- Bootstrap lsp keymappings
    require("plugins.lsp.keymaps")
  end,
}
