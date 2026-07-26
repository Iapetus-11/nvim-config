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

    -- ##### Vue (hybrid mode) + TypeScript/JavaScript #####
    -- vue_ls handles the .vue template/SFC layer; the actual TypeScript comes
    -- from vtsls with @vue/typescript-plugin loaded. Both must run together.
    local vue_language_server_path = vim.fn.expand("$MASON/packages/vue-language-server/node_modules/@vue/language-server")

    -- Shared TS/JS settings (auto-import behaviour + inlay hints). One table
    -- reused for both languages so they stay in lockstep.
    local ts_language_settings = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = { completeFunctionCalls = true },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
    }

    vim.lsp.config("vtsls", {
      filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
        "vue",
      },
      settings = {
        complete_function_calls = true,
        vtsls = {
          enableMoveToFileCodeAction = true,
          autoUseWorkspaceTsdk = true,
          experimental = {
            maxInlayHintLength = 30,
            completion = { enableServerSideFuzzyMatch = true },
          },
          tsserver = {
            globalPlugins = {
              {
                name = "@vue/typescript-plugin",
                location = vue_language_server_path,
                languages = { "vue" },
                configNamespace = "typescript",
                enableForWorkspaceTypeScriptVersions = true,
              },
            },
          },
        },
        typescript = ts_language_settings,
        javascript = ts_language_settings,
      },
    })
    vim.lsp.enable("vtsls")

    vim.lsp.enable("vue_ls")

    -- vtsls code actions + inlay hints, bound buffer-local when it attaches.
    local function ts_code_action(kind)
      return function()
        vim.lsp.buf.code_action({
          apply = true,
          context = { only = { kind }, diagnostics = {} },
        })
      end
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("vtsls_extras", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client or client.name ~= "vtsls" then
          return
        end
        local map = require("utils").map
        map("n", "<leader>co", ts_code_action("source.organizeImports"), { buffer = args.buf, desc = "Organize imports" })
        map("n", "<leader>cM", ts_code_action("source.addMissingImports.ts"), { buffer = args.buf, desc = "Add missing imports" })
        map("n", "<leader>cu", ts_code_action("source.removeUnused.ts"), { buffer = args.buf, desc = "Remove unused" })
        map("n", "<leader>cD", ts_code_action("source.fixAll.ts"), { buffer = args.buf, desc = "Fix all diagnostics" })
        if client:supports_method("textDocument/inlayHint") then
          vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
        end
      end,
    })

    -- Toggle inlay hints for the current buffer (they're on by default in TS).
    require("utils").map("n", "<leader>uh", function()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
    end, { desc = "Toggle inlay hints" })
    -- #####

    -- ESLint diagnostics + code actions (formatting stays with prettier via
    -- conform). Attaches only in projects with an eslint config on disk;
    -- workingDirectories=auto lets it find that config in monorepo subdirs.
    vim.lsp.config("eslint", {
      settings = {
        workingDirectories = { mode = "auto" },
      },
    })
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
