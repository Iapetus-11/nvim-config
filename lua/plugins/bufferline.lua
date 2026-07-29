local utils = require("utils")

local diagnostic_order = {
  { key = "error", severity = vim.diagnostic.severity.ERROR },
  { key = "warning", severity = vim.diagnostic.severity.WARN },
  { key = "info", severity = vim.diagnostic.severity.INFO },
  { key = "hint", severity = vim.diagnostic.severity.HINT },
}

local function diagnostics_indicator(_, _, counts)
  local parts = {}
  for _, level in ipairs(diagnostic_order) do
    local count = counts[level.key]
    if count then
      table.insert(parts, utils.diagnostic_icons[level.severity] .. " " .. count)
    end
  end
  return table.concat(parts, " ")
end

-- Close the current buffer while keeping the window on a real file: move to the
-- next bufferline tab first, then delete what we left behind.
local function close_buffer()
  local target = vim.api.nvim_get_current_buf()

  -- Only listed buffers are bufferline tabs; bail out in help, neo-tree, etc.
  if not vim.bo[target].buflisted then
    vim.notify("Not a bufferline tab", vim.log.levels.WARN)
    return
  end

  if vim.bo[target].modified then
    vim.notify("Buffer has unsaved changes (:w, or :bd! to discard)", vim.log.levels.WARN)
    return
  end

  vim.cmd("BufferLineCycleNext")

  vim.api.nvim_buf_delete(target, {})
end

return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },

  lazy = false,

  keys = {
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "<leader>bh", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },
    { "<leader>bl", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
    { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
    { "<leader>bx", close_buffer, desc = "Close buffer" },
  },

  opts = {
    options = {
      diagnostics = "nvim_lsp",
      diagnostics_indicator = diagnostics_indicator,
      always_show_bufferline = true,
      show_buffer_close_icons = false,
      -- Keep the tabline from spanning over the neo-tree sidebar.
      offsets = {
        {
          filetype = "neo-tree",
          text = "Files",
          highlight = "Directory",
          separator = true,
        },
      },
    },
  },
}
