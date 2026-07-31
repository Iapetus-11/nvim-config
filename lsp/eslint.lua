-- ESLint diagnostics + code actions (formatting stays with prettier via
-- conform). Attaches only in projects with an eslint config on disk;
-- workingDirectories=auto lets it find that config in monorepo subdirs.
return {
  settings = {
    workingDirectories = { mode = "auto" },
  },
}
