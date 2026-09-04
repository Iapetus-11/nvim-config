-- Neovim 0.12.5 can throw from the built-in inlay-hint decoration
-- provider when an LSP returns a stale/invalid hint position:
--   Invalid 'col': out of range
--
-- Patch both ends:
-- 1. Clamp bad LSP inlay-hint responses before Neovim caches them.
-- 2. Guard Neovim's inlay-hint extmarks at render time, because redraws can use
--    already-cached/stale hints after other LSP handlers run.

local orig_set_extmark = vim.api.nvim_buf_set_extmark
local inlay_hint_ns = vim.api.nvim_create_namespace("nvim.lsp.inlayhint")

vim.api.nvim_buf_set_extmark = function(bufnr, ns_id, line, col, opts)
  if ns_id ~= inlay_hint_ns then
    return orig_set_extmark(bufnr, ns_id, line, col, opts)
  end

  local ok, id = pcall(orig_set_extmark, bufnr, ns_id, line, col, opts)
  if ok then
    return id
  end

  local err = tostring(id)
  if not err:match("Invalid 'col': out of range") and not err:match("Invalid 'line'") then
    error(id, 2)
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return 0
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local safe_line = math.max(0, math.min(tonumber(line) or 0, math.max(line_count - 1, 0)))
  local text = vim.api.nvim_buf_get_lines(bufnr, safe_line, safe_line + 1, false)[1] or ""
  local safe_col = math.max(0, math.min(tonumber(col) or 0, #text))

  ok, id = pcall(orig_set_extmark, bufnr, ns_id, safe_line, safe_col, opts)
  if ok then
    return id
  end

  -- Decoration providers don't use the returned id here. Swallow only the
  -- inlay-hint placement failure so it doesn't interrupt editing.
  return 0
end

local inlay_hint = vim.lsp.inlay_hint
local orig_on_inlayhint = inlay_hint.on_inlayhint

local function encoded_line_len(line, encoding)
  if encoding == "utf-8" then
    return #line
  end

  local ok, len = pcall(vim.str_utfindex, line, encoding or "utf-16", #line)
  if ok and type(len) == "number" then
    return len
  end

  return vim.fn.strchars(line)
end

inlay_hint.on_inlayhint = function(err, result, ctx, ...)
  if not err and type(result) == "table" and ctx and ctx.bufnr then
    local bufnr = ctx.bufnr
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local client = ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id)
    local encoding = client and client.offset_encoding or "utf-16"

    for _, hint in ipairs(result) do
      if hint.position then
        local last_lnum = math.max(#lines - 1, 0)
        local lnum = math.max(0, math.min(tonumber(hint.position.line) or 0, last_lnum))
        local line_text = lines[lnum + 1] or ""
        local max_char = encoded_line_len(line_text, encoding)

        hint.position.line = lnum
        hint.position.character = math.max(0, math.min(tonumber(hint.position.character) or 0, max_char))
      end
    end
  end

  return orig_on_inlayhint(err, result, ctx, ...)
end
