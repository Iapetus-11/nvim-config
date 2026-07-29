local utils = require("utils")

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

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
  callback = function(args)
    utils.map("n", "gd", goto_definition, { buffer = args.buf, desc = "Go to definition" })
  end,
})
