local utils = require("utils")
local code_context = require("plugins.lualine.code_context")
local lazy_status = require("lazy.status")
local severity = vim.diagnostic.severity

local HALF_CIRCLE_LEFT = ""
local HALF_CIRCLE_RIGHT = ""

local WHOLE_PATH_PARTS = 3
local MAX_BRANCH_CHARS = 32
local MAX_MODE_CHARS = 3

-- stylua: ignore
local MODE_ABBREVIATIONS = {
  NORMAL      = "NOR",
  INSERT      = "INS",
  VISUAL      = "VIS",
  ["V-LINE"]  = "V-L",
  ["V-BLOCK"] = "V-B",
  SELECT      = "SEL",
  ["S-LINE"]  = "S-L",
  ["S-BLOCK"] = "S-B",
  REPLACE     = "REP",
  ["V-REPLACE"] = "V-R",
  COMMAND     = "CMD",
  EX          = "EX",
  ["O-PENDING"] = "PND",
  MORE        = "MOR",
  CONFIRM     = "CNF",
  SHELL       = "SHL",
  TERMINAL    = "TRM",
}

local function foreground_color_of(highlight_group)
  local highlight = vim.api.nvim_get_hl(0, { name = highlight_group, link = false })
  if not highlight.fg then
    return nil
  end
  return { fg = string.format("#%06x", highlight.fg) }
end

local pending_plugin_updates = {
  lazy_status.updates,
  cond = lazy_status.has_updates,
  color = function()
    return foreground_color_of("Special")
  end,
}

local cursor_scope = {
  code_context.status,
  color = function()
    return foreground_color_of("Comment")
  end,
}

-- Keep the parts that identify the file readable and clip the rest to an initial,
-- so the depth of the path survives at almost no width cost. Trailing state
-- symbols ride along on the last part.
local function shorten_path(path)
  local parts = vim.split(path, "/")
  if #parts <= WHOLE_PATH_PARTS then
    return path
  end

  local split = #parts - WHOLE_PATH_PARTS
  local head = table.concat(vim.list_slice(parts, 1, split), "/")
  local tail = table.concat(vim.list_slice(parts, split + 1), "/")

  -- The trailing separator makes pathshorten treat every head part as a directory.
  return vim.fn.pathshorten(head .. "/", 1) .. tail
end

local file_name = {
  "filename",
  path = 1, -- relative to cwd
  shorting_target = 0, -- otherwise, it'd clip directories to one letter
  fmt = shorten_path,
}

-- lualine falls back to the raw mode code for anything it does not map, so clip
-- and pad to stop the leftmost section resizing every time the mode changes.
local function abbreviate_mode(name)
  local short = vim.fn.strcharpart(MODE_ABBREVIATIONS[name] or name, 0, MAX_MODE_CHARS)
  return short .. string.rep(" ", MAX_MODE_CHARS - vim.fn.strchars(short))
end

local mode = {
  "mode",
  fmt = abbreviate_mode,
  separator = { left = HALF_CIRCLE_LEFT },
  padding = { left = 1, right = 2 },
}

local branch = {
  "branch",
  fmt = function(name)
    if vim.fn.strchars(name) <= MAX_BRANCH_CHARS then
      return name
    end
    return vim.fn.strcharpart(name, 0, MAX_BRANCH_CHARS - 1) .. "…"
  end,
}

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },

  event = "VeryLazy",

  opts = {
    options = {
      theme = "auto",
      component_separators = "|",
      section_separators = { left = HALF_CIRCLE_RIGHT, right = HALF_CIRCLE_LEFT },
    },

    sections = {
      lualine_a = { mode },
      lualine_b = {
        branch,
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        file_name,
        {
          "diagnostics",
          symbols = {
            error = utils.diagnostic_symbol(severity.ERROR),
            warn = utils.diagnostic_symbol(severity.WARN),
            info = utils.diagnostic_symbol(severity.INFO),
            hint = utils.diagnostic_symbol(severity.HINT),
          },
        },
      },
      lualine_c = { cursor_scope },
      lualine_x = { pending_plugin_updates },
      lualine_y = { "progress" },
      lualine_z = {
        { "location", separator = { right = HALF_CIRCLE_RIGHT }, padding = { left = 2, right = 1 } },
      },
    },

    extensions = { "neo-tree", "lazy" },
  },
}
