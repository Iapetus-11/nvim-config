local M = {}

local FUNCTION = "󰊕"
local METHOD = "󰆧"
local CLASS = "󰌗"
local INTERFACE = "󰕘"
local MODULE = ""
local ELEMENT = "󰅩"
local SELECTOR = "󰏘"
local AT_RULE = ""

local MAX_DEPTH = 5
local SEPARATOR = " > "
local ELLIPSIS = "…"

-- `impl_item` names itself with `type`; the other code kinds use `name`.
local NAME_FIELDS = { "name", "type" }

-- Nodes that lend their name to an anonymous value, as in `const foo = () => {}`.
local NAMERS = {
  variable_declarator = true,
  assignment = true,
  assignment_expression = true,
  pair = true,
  field = true,
}

-- Markup nests far deeper than code, so only elements that identify themselves
-- or carry structural meaning earn a place in the chain.
local STRUCTURAL_TAGS = {
  main = true,
  nav = true,
  header = true,
  footer = true,
  aside = true,
  section = true,
  article = true,
  form = true,
  table = true,
  ul = true,
  ol = true,
  li = true,
  dialog = true,
  template = true,
  script = true,
  style = true,
}

local function child_of_type(node, wanted)
  for child in node:iter_children() do
    if child:type() == wanted then
      return child
    end
  end
end

local function field_text(node, bufnr)
  for _, field in ipairs(NAME_FIELDS) do
    local named = node:field(field)[1]
    if named then
      return vim.treesitter.get_node_text(named, bufnr)
    end
  end
end

local function code_name(node, bufnr)
  local name = field_text(node, bufnr)
  if name then
    return name
  end

  local parent = node:parent()
  if parent and NAMERS[parent:type()] then
    return field_text(parent, bufnr)
  end
end

local function attribute_value(attribute, bufnr)
  local value = child_of_type(attribute, "quoted_attribute_value") or child_of_type(attribute, "attribute_value")
  if not value then
    return
  end
  return vim.treesitter.get_node_text(child_of_type(value, "attribute_value") or value, bufnr)
end

-- Renders an element the way a stylesheet would name it: `div#app.container.main`.
local function element_name(node, bufnr)
  local start_tag = child_of_type(node, "start_tag") or child_of_type(node, "self_closing_tag")
  if not start_tag then
    return
  end

  local tag_name = child_of_type(start_tag, "tag_name")
  if not tag_name then
    return
  end

  local tag = vim.treesitter.get_node_text(tag_name, bufnr)
  local id, classes

  for child in start_tag:iter_children() do
    if child:type() == "attribute" then
      local attribute_name = child_of_type(child, "attribute_name")
      local name = attribute_name and vim.treesitter.get_node_text(attribute_name, bufnr)
      if name == "id" then
        id = attribute_value(child, bufnr)
      elseif name == "class" then
        classes = attribute_value(child, bufnr)
      end
    end
  end

  if not id and not classes and not STRUCTURAL_TAGS[tag] then
    return
  end

  local label = tag
  if id then
    label = label .. "#" .. id
  end
  for class in vim.gsplit(classes or "", "%s+", { trimempty = true }) do
    label = label .. "." .. class
  end
  return label
end

local function collapse(text)
  local collapsed = text:gsub("%s+", " ")
  return collapsed
end

local function selector_name(node, bufnr)
  local selectors = child_of_type(node, "selectors")
  if selectors then
    return collapse(vim.treesitter.get_node_text(selectors, bufnr))
  end
end

-- Everything an at-rule declares before its body, so `@media` keeps its query.
local function at_rule_name(node, bufnr)
  local parts = {}
  for child in node:iter_children() do
    local type = child:type()
    if type == "block" or type == "keyframe_block_list" then
      break
    end
    table.insert(parts, collapse(vim.treesitter.get_node_text(child, bufnr)))
  end
  if #parts > 0 then
    return table.concat(parts, " ")
  end
end

-- Treesitter node types worth naming, keyed by type because the grammars
-- disagree on names but agree on meaning. `name` defaults to `code_name`.
local kinds = {
  -- lua (an anonymous `function_definition` has no name field, so it drops out)
  function_declaration = { icon = FUNCTION, callable = true },

  -- python
  function_definition = { icon = FUNCTION, callable = true },
  class_definition = { icon = CLASS },

  -- rust
  function_item = { icon = FUNCTION, callable = true },
  struct_item = { icon = CLASS },
  enum_item = { icon = INTERFACE },
  trait_item = { icon = INTERFACE },
  impl_item = { icon = CLASS },
  mod_item = { icon = MODULE },

  -- typescript / javascript
  method_definition = { icon = METHOD, callable = true },
  class_declaration = { icon = CLASS },
  interface_declaration = { icon = INTERFACE },
  enum_declaration = { icon = INTERFACE },
  arrow_function = { icon = FUNCTION, callable = true },
  function_expression = { icon = FUNCTION, callable = true },

  -- html (`style` and `script` get their own node types, and marking them keeps
  -- the language boundary visible once an injected tree takes over)
  element = { icon = ELEMENT, name = element_name },
  style_element = { icon = ELEMENT, name = element_name },
  script_element = { icon = ELEMENT, name = element_name },

  -- css / scss
  rule_set = { icon = SELECTOR, name = selector_name },
  media_statement = { icon = AT_RULE, name = at_rule_name },
  supports_statement = { icon = AT_RULE, name = at_rule_name },
  keyframes_statement = { icon = AT_RULE, name = at_rule_name },
}

-- Scopes from a single language tree, outermost first.
local function scopes_in(tree, range, bufnr)
  local node = tree:named_node_for_range(range, { ignore_injections = true })
  local scopes = {}

  while node do
    local kind = kinds[node:type()]
    if kind then
      local name = (kind.name or code_name)(node, bufnr)
      if name then
        table.insert(scopes, 1, kind.icon .. " " .. name .. (kind.callable and "()" or ""))
      end
    end
    node = node:parent()
  end

  return scopes
end

local function context_at(bufnr, cursor)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return ""
  end

  local row, col = cursor[1] - 1, cursor[2]
  local range = { row, col, row, col }

  -- An injected tree's root has no parent node, so the chain is stitched one
  -- language at a time to keep the scopes that enclose the injection.
  local scopes = {}
  ---@type vim.treesitter.LanguageTree?
  local tree = parser:language_for_range(range)
  while tree do
    scopes = vim.list_extend(scopes_in(tree, range, bufnr), scopes)
    tree = tree:parent()
  end

  -- Keep the innermost scopes; they say the most about where the cursor sits.
  if #scopes > MAX_DEPTH then
    scopes = vim.list_slice(scopes, #scopes - MAX_DEPTH + 1)
    table.insert(scopes, 1, ELLIPSIS)
  end

  return table.concat(scopes, SEPARATOR)
end

-- The scopes only change when the cursor or the text moves, so redraws in
-- between reuse the last result.
local last = { key = nil, context = "" }

function M.status()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local key = table.concat({ bufnr, vim.b[bufnr].changedtick, cursor[1], cursor[2] }, ":")

  if key ~= last.key then
    last.key = key
    last.context = context_at(bufnr, cursor)
  end

  return last.context
end

return M
