local PARSERS = {
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
}

local function use_treesitter_folds()
  vim.wo[0][0].foldmethod = "expr"
  vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",

  config = function()
    -- The schedule keep the directory scan off the startup path.
    vim.schedule(function()
      require("nvim-treesitter").install(PARSERS)
    end)

    vim.treesitter.language.register("json", "jsonc")

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
      callback = function(args)
        if not pcall(vim.treesitter.start, args.buf) then
          return
        end

        if vim.api.nvim_get_current_buf() == args.buf then
          use_treesitter_folds()
        end
      end,
    })
  end,
}
