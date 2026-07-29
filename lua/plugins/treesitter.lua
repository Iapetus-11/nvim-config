local UNFOLDED = 99

local function install_missing_parsers(wanted)
  local nvim_treesitter = require("nvim-treesitter")
  local installed = nvim_treesitter.get_installed()
  local missing = vim.tbl_filter(function(parser)
    return not vim.list_contains(installed, parser)
  end, wanted)

  if #missing > 0 then
    nvim_treesitter.install(missing)
  end
end

local function buf_is_displayed_here(buf)
  return vim.api.nvim_get_current_buf() == buf
end

local function use_treesitter_folds()
  vim.wo[0][0].foldmethod = "expr"
  vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false,

  init = function()
    vim.opt.foldlevel = UNFOLDED
    vim.opt.foldlevelstart = UNFOLDED
  end,

  config = function()
    install_missing_parsers({
      "lua",
      "luadoc",
      "vim",
      "vimdoc",
      "query",
      "python",
      "rust",
      "typescript",
      "javascript",
      "tsx",
      "vue",
      "bash",
      "html",
      "css",
      "scss",
      "json",
      "yaml",
      "toml",
      "markdown",
      "markdown_inline",
      "diff",
      "gitcommit",
      "git_config",
      "gitignore",
      "regex",
    })

    vim.treesitter.language.register("json", "jsonc")

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
      callback = function(args)
        if not pcall(vim.treesitter.start, args.buf) then
          return
        end

        if buf_is_displayed_here(args.buf) then
          use_treesitter_folds()
        end
      end,
    })
  end,
}
