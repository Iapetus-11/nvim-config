-- vue_ls offers already-imported components a second time as an
-- auto-import, and will duplicate the import line (vuejs/language-tools#5540).
-- Returns a blink.cmp transform_items that drops the twin when the same
-- name is already in scope.
return function(ctx, items)
  if vim.bo[ctx.bufnr].filetype ~= "vue" then
    return items
  end

  local in_scope = {}
  for _, item in ipairs(items) do
    if not vim.startswith(item.sortText or "", "\u{FFFF}") then
      in_scope[item.label] = true
    end
  end
  return vim.tbl_filter(function(item)
    return not (vim.startswith(item.sortText or "", "\u{FFFF}") and in_scope[item.label])
  end, items)
end
