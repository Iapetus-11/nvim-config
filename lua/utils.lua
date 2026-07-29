local M = {}

M.diagnostic_icons = {
  [vim.diagnostic.severity.ERROR] = "",
  [vim.diagnostic.severity.WARN] = "",
  [vim.diagnostic.severity.INFO] = "",
  [vim.diagnostic.severity.HINT] = "󰌵",
}

-- Statusline and tabline consumers append a count, so the separating space
-- belongs to the symbol rather than to each call site.
function M.diagnostic_symbol(severity)
  return M.diagnostic_icons[severity] .. " "
end

-- Set a keymap with sane defaults
function M.map(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { silent = true, noremap = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

return M
