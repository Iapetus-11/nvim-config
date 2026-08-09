return {
  "saghen/blink.cmp",
  version = "1.*",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "super-tab" },

    sources = {
      providers = {
        lsp = { transform_items = require("patches.vue-duplicate-auto-import") },
      },
    },

    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 250 },
    },

    signature = { enabled = true },
  },
}
