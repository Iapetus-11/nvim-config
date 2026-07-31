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
      table.insert(parts, utils.diagnostic_symbol(level.severity) .. count)
    end
  end
  return table.concat(parts, " ")
end

-- Tab clicks and cycling both act on the focused window. Run from neo-tree,
-- they displace the tree, which then reopens on the far side of the layout.
local function editor_window()
  return vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function(win)
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "neo-tree"
  end)
end

local function in_editor_window(action)
  return function(...)
    if vim.bo.buftype ~= "" or vim.bo.filetype == "neo-tree" then
      local win = editor_window()
      if not win then
        return
      end
      vim.api.nvim_set_current_win(win)
    end
    action(...)
  end
end

-- Close the current buffer while keeping the window on a real file
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
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "catppuccin/nvim",
  },

  lazy = false,

  keys = {
    {
      "<S-h>",
      in_editor_window(function()
        vim.cmd("BufferLineCyclePrev")
      end),
      desc = "Previous buffer",
    },
    {
      "<S-l>",
      in_editor_window(function()
        vim.cmd("BufferLineCycleNext")
      end),
      desc = "Next buffer",
    },
    { "<leader>bh", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },
    { "<leader>bl", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
    { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
    { "<leader>bx", close_buffer, desc = "Close buffer" },
  },

  -- A function, because the catppuccin palette only exists after catppuccin sets up.
  opts = function()
    return {
      options = {
        diagnostics = "nvim_lsp",
        diagnostics_indicator = diagnostics_indicator,
        left_mouse_command = in_editor_window(vim.api.nvim_set_current_buf),
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

      highlights = require("catppuccin.special.bufferline").get_theme(),
    }
  end,
}
