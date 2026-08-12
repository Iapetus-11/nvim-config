-- vim.lsp.buf.code_action lists actions in client order with disabled ones
-- mixed in. Reordering at the ui.select boundary puts preferred fixes on top
-- and disabled actions last, while keeping everything visible.

local RANKS = { preferred = 1, normal = 2, disabled = 3 }

local function rank(item)
  local action = item.action or {}
  if action.disabled then
    return RANKS.disabled
  end
  if action.isPreferred then
    return RANKS.preferred
  end
  return RANKS.normal
end

local select = vim.ui.select

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(items, opts, on_choice)
  if opts and opts.kind == "codeaction" then
    -- table.sort is unstable, so ties keep their place through the index.
    local index = {}
    for position, item in ipairs(items) do
      index[item] = position
    end

    items = vim.list_slice(items)
    table.sort(items, function(a, b)
      if rank(a) ~= rank(b) then
        return rank(a) < rank(b)
      end
      return index[a] < index[b]
    end)
  end

  return select(items, opts, on_choice)
end
