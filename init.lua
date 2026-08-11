-- The leaders must be set before lazy.nvim loads so plugin mappings use them.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.undofile = true
vim.opt.clipboard = "unnamedplus"

-- The terminal tab shows this title instead of a bare "nvim".
vim.opt.title = true
vim.opt.titlestring = "nvim - %{fnamemodify(getcwd(), ':t')}"

vim.opt.laststatus = 3
vim.opt.showmode = false
vim.o.winborder = "rounded"

-- Treesitter supplies the fold expression; start with all folds open.
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- The python3 provider only runs Python remote plugins, which I am not using right now
-- so this saves a lot of time opening Python files
vim.g.loaded_python3_provider = 0

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

-- `autoread` only applies when a check is triggered, so trigger one on re-entry.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  desc = "Reload files changed on disk",
  callback = function()
    if vim.o.buftype == "" then
      vim.cmd.checktime()
    end
  end,
})

require("config.indent")
require("config.lazy")
