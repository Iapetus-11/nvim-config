local function center_after_jump()
  vim.api.nvim_create_autocmd("CursorMoved", {
    once = true,
    callback = function()
      vim.cmd("normal! zz")
    end,
  })
end

local function goto_definition()
  vim.lsp.buf.definition()
  center_after_jump()
end

local function ts_code_action(kind)
  return function()
    vim.lsp.buf.code_action({
      apply = true,
      context = { only = { kind }, diagnostics = {} },
    })
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
  callback = function(args)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end

    map("gd", goto_definition, "Go to definition")

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "vtsls" then
      map("<leader>co", ts_code_action("source.organizeImports"), "Organize imports")
      map("<leader>cM", ts_code_action("source.addMissingImports.ts"), "Add missing imports")
      map("<leader>cu", ts_code_action("source.removeUnused.ts"), "Remove unused")
      map("<leader>cD", ts_code_action("source.fixAll.ts"), "Fix all diagnostics")

      -- Inlay hints start enabled in TS; <leader>uh toggles them per buffer.
      if client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      end
    end
  end,
})
