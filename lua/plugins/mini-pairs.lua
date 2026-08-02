return {
  "echasnovski/mini.pairs",
  version = "*",
  event = "InsertEnter",

  opts = {
    mappings = {
      -- Ensure Rust lifetimes (`&'a`) do not gain a closing quote.
      ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%a\\&]." },
    },
  },
}
