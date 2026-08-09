-- vtsls updates rename imports only for JS/TS. Patch tsserver to work with .vue files.
local M = {}

---@param path string
---@return vim.lsp.Client?
local function vtsls_owning(path)
  for _, client in ipairs(vim.lsp.get_clients({ name = "vtsls" })) do
    if client.root_dir and vim.fs.relpath(client.root_dir, path) then
      return client
    end
  end
end

-- tsserver spans are 1-based line/offset; LSP is 0-based
---@param body table tsserver FileCodeEdits[]
---@return lsp.WorkspaceEdit
local function to_workspace_edit(body)
  local changes = {}
  for _, file in ipairs(body) do
    changes[vim.uri_from_fname(file.fileName)] = vim.tbl_map(function(change)
      return {
        newText = change.newText,
        range = {
          start = { line = change.start.line - 1, character = change.start.offset - 1 },
          ["end"] = { line = change["end"].line - 1, character = change["end"].offset - 1 },
        },
      }
    end, file.textChanges)
  end
  return { changes = changes }
end

---@param args { source: string, destination: string }
local function rename_vue_importers(args)
  local old, new = args.source, args.destination
  if not old:match("%.vue$") then
    return
  end

  local client = vtsls_owning(old)
  if not client then
    return
  end

  local resp = client:request_sync("workspace/executeCommand", {
    command = "typescript.tsserverRequest",
    arguments = { "getEditsForFileRename", { oldFilePath = old, newFilePath = new } },
  }, require("lsp-file-operations").config.timeout_ms)

  if not resp or resp.err then
    vim.notify(
      ("Could not update importers of %s: %s"):format(vim.fs.basename(old), resp and resp.err.message or "timed out"),
      vim.log.levels.WARN
    )
    return
  end

  local body = vim.tbl_get(resp, "result", "body")
  if body then
    vim.lsp.util.apply_workspace_edit(to_workspace_edit(body), client.offset_encoding)
  end
end

function M.setup()
  local events = require("neo-tree.events")
  for _, event in ipairs({ events.BEFORE_FILE_RENAME, events.BEFORE_FILE_MOVE }) do
    events.subscribe({
      id = "vue-rename." .. event,
      event = event,
      handler = rename_vue_importers,
    })
  end
end

return M
