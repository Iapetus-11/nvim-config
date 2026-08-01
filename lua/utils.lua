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

local TERMINAL_ICON = ""

function M.terminal_tab()
  local id = (vim.b.snacks_terminal or {}).id
  local title = (vim.b.term_title or vim.o.shell):gsub("%%", "%%%%")
  -- `%<` clips the title rather than the number it sits after.
  return (" %s %s%%<%s "):format(TERMINAL_ICON, id and id .. ": " or "", title)
end

return M
