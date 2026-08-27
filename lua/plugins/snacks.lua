local last_terminal_id
local toggling_panel = false

local function terminal_id(term)
  return vim.b[term.buf].snacks_terminal.id
end

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

-- Snacks keys a terminal by its count, so reused numbers replace each other.
local function new_terminal()
  local used = {}
  for _, term in ipairs(Snacks.terminal.list()) do
    used[vim.b[term.buf].snacks_terminal.id] = true
  end

  local id = 1
  while used[id] do
    id = id + 1
  end

  Snacks.terminal.open(nil, { count = id })
end

local function toggle_panel()
  local terminals = Snacks.terminal.list()
  if #terminals == 0 then
    return new_terminal()
  end

  if vim.b.snacks_terminal then
    last_terminal_id = vim.b.snacks_terminal.id
  end

  -- list() is hash-ordered, so show in id order to keep the arrangement stable.
  table.sort(terminals, function(a, b)
    return terminal_id(a) < terminal_id(b)
  end)

  local hide = #panel() > 0
  local focus_id = last_terminal_id
  local focus_win

  -- Hiding/showing several split terminals fires BufEnter as Neovim moves
  -- through the remaining windows. Don't let those transient focus changes
  -- replace the terminal the user actually had focused.
  toggling_panel = true
  for _, term in ipairs(terminals) do
    if hide then
      term:hide()
    else
      term:show()
      if terminal_id(term) == focus_id then
        focus_win = term.win
      end
    end
  end
  toggling_panel = false

  if focus_win and vim.api.nvim_win_is_valid(focus_win) then
    vim.api.nvim_set_current_win(focus_win)
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

-- Nvim aborts a quit whose starting window an autocommand closed.
local function retry_exit_from_panel()
  if vim.b.snacks_terminal then
    vim.schedule(function()
      vim.cmd("qa")
    end)
  end
end

local function remember_terminal()
  if not toggling_panel and vim.b.snacks_terminal then
    last_terminal_id = vim.b.snacks_terminal.id
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
    vim.api.nvim_create_autocmd("BufEnter", { callback = remember_terminal })
  end,

  keys = {
    {
      "<leader>G",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },
    { "<C-\\>", toggle_panel, mode = { "n", "t" }, nowait = true, desc = "Toggle terminal panel" },
    { "<leader>tt", terminal("toggle"), desc = "Toggle terminal" },
    { "<leader>tn", new_terminal, desc = "New terminal" },
  },

  ---@module 'snacks'
  ---@type snacks.Config
  opts = {
    terminal = {
      auto_close = false,
      auto_insert = true,
      start_insert = true,

      win = {
        position = "bottom",
        height = 0.3,
        wo = {
          winbar = "%{%v:lua.require'utils'.terminal_tab()%}",
          winhighlight = "",
        },
        keys = {
          next_terminal = { "<S-l>", cycle_terminal(1), desc = "Next terminal" },
          prev_terminal = { "<S-h>", cycle_terminal(-1), desc = "Previous terminal" },
        },
      },
    },
  },
}
