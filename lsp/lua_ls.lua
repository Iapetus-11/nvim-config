-- lazydev owns runtime.version, workspace.library and checkThirdParty; it
-- applies them per project instead of to every Lua workspace.
return {
  settings = {
    Lua = {
      diagnostics = {
        groupFileStatus = {
          ambiguity = "Any",
          duplicate = "Any",
          global = "Any",
          luadoc = "Any",
          redefined = "Any",
          ["type-check"] = "Any",
          unbalanced = "Any",

          await = "Opened",
          strict = "Opened",
          unused = "Opened",

          codestyle = "None",
          conventions = "None",
          strong = "None",
        },
        workspaceEvent = "OnChange",
        workspaceDelay = 200,
        workspaceRate = 100,
      },
    },
  },
}
