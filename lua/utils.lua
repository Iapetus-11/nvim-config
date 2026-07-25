local M = {}

-- Set a keymap with sane defaults (silent, non-recursive).
function M.map(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { silent = true, noremap = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

return M
