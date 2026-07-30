return {
  "saghen/blink.cmp",
  version = "1.*",

  lazy = false,

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "super-tab" },

    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 250 },
    },

    signature = { enabled = true },
  },
}
