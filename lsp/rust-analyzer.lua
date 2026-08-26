return {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allTargets = true,
        features = "all",
      },

      check = {
        command = "clippy",
        extraArgs = { "--", "-A", "unused" },
      },

      rustc = { source = "discover" },

      files = { excludeDirs = { "target", ".direnv" } },

      imports = {
        granularity = { group = "module" },
        prefix = "self",
      },

      completion = {
        callable = { snippets = "fill_arguments" },
        fullFunctionSignatures = { enable = true },
      },

      inlayHints = {
        closureReturnTypeHints = { enable = "with_block" },
        chainingHints = { enable = true },
        parameterHints = { enable = true },
        maxLength = 25,
      },
    },
  },
}
