-- plugins/guess-indent.nvim overrides everything here once a file shows its own style,
-- so these values only decide new and styleless files.
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

vim.g.python_indent = {
  closed_paren_align_last_line = false,
}

local FILETYPE_INDENT = {
  lua = 2,
  markdown = 2,
}

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("filetype_indent", { clear = true }),
  callback = function(args)
    local width = FILETYPE_INDENT[args.match]
    if width then
      vim.bo[args.buf].shiftwidth = width
      vim.bo[args.buf].tabstop = width
      vim.bo[args.buf].softtabstop = width
    end
  end,
})
