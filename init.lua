vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.undofile = true

vim.opt.laststatus = 3

-- `:h` splits the current window by default, which squeezes whatever file is
-- open. Move it to its own tabpage instead so the layout is left untouched.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  desc = "Open help in its own tabpage",
  callback = function()
    if vim.bo.buftype == "help" and #vim.api.nvim_tabpage_list_wins(0) > 1 then
      vim.cmd("wincmd T")
    end
  end,
})

require("config.lazy")
