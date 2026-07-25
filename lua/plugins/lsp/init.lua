return {
  "neovim/nvim-lspconfig",

  cmd = { "LspStart", "LspStop", "LspRestart", "LspLog" },
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
    vim.lsp.enable("bashls")

    -- ##### Vue (hybrid mode) #####
    -- vue_ls handles the .vue template/SFC layer; the actual TypeScript comes
    -- from vtsls with @vue/typescript-plugin loaded. Both must run together.
    local vue_language_server_path = vim.fn.expand("$MASON/packages/vue-language-server/node_modules/@vue/language-server")

    vim.lsp.config("vtsls", {
      settings = {
        vtsls = {
          tsserver = {
            globalPlugins = {
              {
                name = "@vue/typescript-plugin",
                location = vue_language_server_path,
                languages = { "vue" },
                configNamespace = "typescript",
              },
            },
          },
        },
      },
      filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
    })
    vim.lsp.enable("vtsls")

    vim.lsp.enable("vue_ls")
    -- #####

    -- ESLint diagnostics + code actions (formatting stays with prettier via
    -- conform). Attaches only in projects with an eslint config on disk.
    vim.lsp.enable("eslint")

    vim.lsp.config("rust_analyzer", {
      settings = {
        ["rust-analyzer"] = {
          checkOnSave = true,
          check = {
            command = "clippy",
            workspace = true,
            features = "all",
          },
        },
      },
    })
    vim.lsp.enable("rust_analyzer")

    require("lspconfig.ui.windows").default_options.border = "single"

    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "ruff", "html", "bashls", "rust-analyzer", "vtsls", "vue_ls", "eslint" },
      automatic_enable = false,
    })

    -- Bootstrap lsp keymappings
    require("plugins.lsp.keymaps")
  end,
}
