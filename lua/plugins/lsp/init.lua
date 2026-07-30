local utils = require("utils")

local SERVERS = {
  "lua_ls",
  "ruff",
  "html",
  "bashls",
  "vtsls",
  "vue_ls",
  "eslint",
  "rust_analyzer",
}

-- Shared TS/JS settings
local TS_LANGUAGE_SETTINGS = {
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

local function show_line_diagnostic()
  vim.diagnostic.config({
    float = {
      show_header = true,
      source = "if_many",
      border = "rounded",
      focusable = false,
    },
  })
  vim.diagnostic.open_float()
end

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
    "mason-org/mason-lspconfig.nvim",
  },

  keys = {
    { "<Leader>?", show_line_diagnostic, desc = "Show line diagnostic" },
  },

  config = function()
    require("neoconf").setup()

    require("plugins.lsp.keymaps")

    vim.diagnostic.config({
      virtual_text = false,
      virtual_lines = { current_line = true },
      signs = { text = utils.diagnostic_icons },
    })

    -- lazydev owns runtime.version, workspace.library and checkThirdParty; it
    -- applies them per project instead of to every Lua workspace.
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
        },
      },
    })

    -- ##### Python #####
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

    -- ##### Vue (hybrid mode) + TypeScript/JavaScript #####
    -- vue_ls handles the .vue template/SFC layer; the actual TypeScript comes
    -- from vtsls with @vue/typescript-plugin loaded. Both must run together.
    -- Stays inside `config`: mason only exports $MASON once it loads, which is
    -- after every plugin spec has been read.
    local vue_language_server_path = vim.fn.expand("$MASON/packages/vue-language-server/node_modules/@vue/language-server")

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
        typescript = TS_LANGUAGE_SETTINGS,
        javascript = TS_LANGUAGE_SETTINGS,
      },
    })

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
        local map = utils.map
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
    utils.map("n", "<leader>uh", toggle_inlay_hints, { desc = "Toggle inlay hints" })
    -- #####

    -- ESLint diagnostics + code actions (formatting stays with prettier via
    -- conform). Attaches only in projects with an eslint config on disk;
    -- workingDirectories=auto lets it find that config in monorepo subdirs.
    vim.lsp.config("eslint", {
      settings = {
        workingDirectories = { mode = "auto" },
      },
    })

    vim.lsp.config("rust_analyzer", {
      settings = {
        ["rust-analyzer"] = {
          checkOnSave = true,
          check = {
            command = "clippy",
            extraArgs = { "--", "-A", "unused" },
            workspace = true,
            features = "all",
          },
        },
      },
    })

    vim.lsp.enable(SERVERS)

    require("lspconfig.ui.windows").default_options.border = "single"

    require("mason-lspconfig").setup({
      ensure_installed = SERVERS,
      automatic_enable = false,
    })
  end,
}
