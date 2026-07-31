return {
  settings = {
    ["rust-analyzer"] = {
      check = {
        command = "clippy",
        extraArgs = { "--", "-A", "unused" },
        features = "all",
      },
    },
  },
}
