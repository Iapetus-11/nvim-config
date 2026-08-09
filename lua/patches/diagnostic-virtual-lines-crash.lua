-- nvim's virtual_lines current_line handler registers a CursorMoved
-- callback that crashes when lines are deleted after render (neovim/neovim#16449).
-- The render is cosmetic and self-heals on the next publish, so re-register
-- that callback wrapped in pcall.
local orig = vim.diagnostic.handlers.virtual_lines

vim.diagnostic.handlers.virtual_lines = {
  hide = orig.hide,
  show = function(namespace, bufnr, diagnostics, opts)
    orig.show(namespace, bufnr, diagnostics, opts)

    local group = string.format("nvim.%s.diagnostic.virt_lines", vim.diagnostic.get_namespace(namespace).name)
    local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
      group = group,
      event = "CursorMoved",
      buffer = bufnr,
    })
    if not ok then
      return
    end

    for _, au in ipairs(autocmds) do
      if au.callback then
        local callback = au.callback
        vim.api.nvim_del_autocmd(au.id)
        vim.api.nvim_create_autocmd("CursorMoved", {
          group = group,
          buffer = bufnr,
          callback = function(event)
            pcall(callback, event)
          end,
        })
      end
    end
  end,
}
