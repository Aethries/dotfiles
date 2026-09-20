-- ==============================================================================
-- Generator: Keymap Manifest -> Antigravity JSONC & Markdown Documentation
-- Run with: nvim -l scripts/generate-keymaps.lua
-- ==============================================================================

local script_path = debug.getinfo(1, "S").source:sub(2)
local repo_root = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(script_path)))
package.path = repo_root .. "/resources/nvim/lua/?.lua;" .. repo_root .. "/resources/nvim/lua/?/init.lua;" .. package.path

local manifest = require("keymaps.manifest")

-- 1. Validate manifest uniqueness
local seen = {}
for _, entry in ipairs(manifest.entries) do
  for _, m in ipairs(entry.modes) do
    local id = m .. ":" .. entry.key
    if seen[id] then
      io.stderr:write("Error: Duplicate keybinding in manifest: " .. id .. "\n")
      os.exit(1)
    end
    seen[id] = true
  end
end

-- 2. Generate keymaps/generated-doc.md
local doc_lines = {
  "# Unified Workstation Keymap Reference (Issue #30)",
  "",
  "> Auto-generated from `resources/nvim/lua/keymaps/manifest.lua`. Workstation-wide single source of truth.",
  "",
  "## 1. Universal Modal Grammar (Quy tắc bất biến toàn hệ thống)",
  "",
  "| Khái niệm (Concept) | Phím chuẩn (Key) | Phạm vi (Scope) | Hành vi đồng bộ (Unified Behavior) |",
  "| :--- | :--- | :--- | :--- |",
}

if manifest.global_grammar then
  for _, g in ipairs(manifest.global_grammar) do
    table.insert(
      doc_lines,
      string.format("| **%s** | `%s` | %s | %s |", g.concept, g.key, g.scope, g.behavior)
    )
  end
end

table.insert(doc_lines, "")
table.insert(doc_lines, "## 2. Workstation Layer Hierarchy (Phân cấp Layer)")
table.insert(doc_lines, "")
table.insert(doc_lines, "| Layer | Tên hiển thị | Trách nhiệm chính | Phần mềm chủ quản |")
table.insert(doc_lines, "| :--- | :--- | :--- | :--- |")

if manifest.workstation_layers then
  local layer_order = { "normal", "navigate", "super", "chromium", "terminals", "niri", "visual", "warpd" }
  for _, lk in ipairs(layer_order) do
    local l = manifest.workstation_layers[lk]
    if l then
      table.insert(doc_lines, string.format("| `%s` | %s | %s | %s |", lk, l.name, l.desc, l.ownership))
    end
  end
end

table.insert(doc_lines, "")
table.insert(doc_lines, "## 3. Editor & IDE Keymaps (Neovim / Antigravity)")
table.insert(doc_lines, "")
table.insert(doc_lines, "| Modes | Key | Group | Description | Native Action | Antigravity Action |")
table.insert(doc_lines, "| :--- | :--- | :--- | :--- | :--- | :--- |")

for _, entry in ipairs(manifest.entries) do
  local modes = table.concat(entry.modes, ", ")
  local key = "`" .. entry.key:gsub("|", "\\|") .. "`"
  local group = entry.group or "general"
  local desc = entry.desc or ""
  local native = type(entry.native) == "string" and ("`" .. entry.native:gsub("|", "\\|") .. "`") or "function"
  local vscode = entry.vscode and ("`" .. entry.vscode:gsub("|", "\\|") .. "`") or "-"

  table.insert(
    doc_lines,
    string.format("| %s | %s | %s | %s | %s | %s |", modes, key, group, desc, native, vscode)
  )
end

local doc_content = table.concat(doc_lines, "\n") .. "\n"
local doc_path = repo_root .. "/resources/nvim/keymaps/generated-doc.md"
vim.fn.mkdir(vim.fs.dirname(doc_path), "p")
local f_doc = io.open(doc_path, "w")
if f_doc then
  f_doc:write(doc_content)
  f_doc:close()
  print("✓ Generated: resources/nvim/keymaps/generated-doc.md")
else
  io.stderr:write("Error: Could not write to " .. doc_path .. "\n")
  os.exit(1)
end

print("✓ All keymaps verified and generated successfully.")
