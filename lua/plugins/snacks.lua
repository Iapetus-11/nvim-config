local function panel()
  return vim.tbl_filter(function(term)
    return term:win_valid()
  end, Snacks.terminal.list())
end

local function terminal(action, opts)
  return function()
    Snacks.terminal[action](nil, opts)
  end
end

local function toggle_panel()
  local terminals = Snacks.terminal.list()
  if #terminals == 0 then
    return Snacks.terminal.open()
  end

  local hide = #panel() > 0
  for _, term in ipairs(terminals) do
    if hide then
      term:hide()
    else
      term:show()
    end
  end
end

local function cycle_terminal(step)
  return function(current)
    local terminals = panel()
    table.sort(terminals, function(a, b)
      return vim.api.nvim_win_get_position(a.win)[2] < vim.api.nvim_win_get_position(b.win)[2]
    end)

    for index, term in ipairs(terminals) do
      if term == current then
        vim.api.nvim_set_current_win(terminals[(index - 1 + step) % #terminals + 1].win)
        return
      end
    end
  end
end

-- `auto_close = false` drops the non-zero exit report; closing is still wanted.
local function close_exited_terminal(event)
  for _, term in ipairs(Snacks.terminal.list()) do
    if term.buf == event.buf then
      term:close()
      vim.cmd.checktime()
      return
    end
  end
end

-- Nvim aborts a quit whose starting window an autocommand closed, and snacks
-- closes its terminals on exit. So ask again once the panel is gone.
local function retry_exit_from_panel()
  if vim.b.snacks_terminal then
    vim.schedule(function()
      vim.cmd("qa")
    end)
  end
end

local function link_tab_highlights()
  vim.api.nvim_set_hl(0, "WinBar", { link = "BufferLineBufferSelected" })
  vim.api.nvim_set_hl(0, "WinBarNC", { link = "BufferLineBackground" })
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,

  init = function()
    vim.opt.splitkeep = "screen"
    link_tab_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = link_tab_highlights })
    vim.api.nvim_create_autocmd("TermClose", { callback = close_exited_terminal })
    vim.api.nvim_create_autocmd("ExitPre", { callback = retry_exit_from_panel })
  end,

  keys = {
    { "<C-\\>", toggle_panel, mode = { "n", "t" }, desc = "Toggle terminal panel" },
    { "<leader>tt", terminal("toggle"), desc = "Toggle terminal" },
    { "<leader>tn", terminal("open"), desc = "New terminal" },
    { "<leader>tf", terminal("toggle", { win = { position = "float" } }), desc = "Floating terminal" },
  },

  ---@module 'snacks'
  ---@type snacks.Config
  opts = {
    terminal = {
      auto_close = false,

      win = {
        position = "bottom",
        height = 0.3,
        wo = { winbar = "%{%v:lua.require'utils'.terminal_tab()%}" },
        keys = {
          next_terminal = { "<S-l>", cycle_terminal(1), desc = "Next terminal" },
          prev_terminal = { "<S-h>", cycle_terminal(-1), desc = "Previous terminal" },
        },
      },
    },
  },
}
