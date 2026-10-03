local M = {}

function M.setup()
  local ok, base16 = pcall(require, 'base16-colorscheme')
  if not ok then
    return
  end

  base16.setup({
    base00 = '{{colors.surface.default.hex}}',
    base01 = '{{colors.surface_container.default.hex}}',
    base02 = '{{colors.surface_container_high.default.hex}}',
    base03 = '{{colors.outline.default.hex}}',
    base04 = '{{colors.on_surface_variant.default.hex}}',
    base05 = '{{colors.on_surface.default.hex}}',
    base06 = '{{colors.on_surface.default.hex}}',
    base07 = '{{colors.on_background.default.hex}}',
    base08 = '{{colors.error.default.hex}}',
    base09 = '{{colors.tertiary.default.hex}}',
    base0A = '{{colors.secondary.default.hex}}',
    base0B = '{{colors.primary.default.hex}}',
    base0C = '{{colors.tertiary_fixed_dim.default.hex}}',
    base0D = '{{colors.primary_fixed_dim.default.hex}}',
    base0E = '{{colors.secondary_fixed_dim.default.hex}}',
    base0F = '{{colors.secondary_fixed.default.hex}}',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '{{colors.surface_container_high.default.hex}}', bg = 'NONE' })
  hi('VertSplit',               { fg = '{{colors.surface_container_high.default.hex}}', bg = 'NONE' })
  hi('CursorLine',              { bg = '{{colors.surface_container.default.hex}}' })
  hi('CursorLineNr',            { fg = '{{colors.secondary.default.hex}}',             bold = true })
  hi('LineNr',                  { fg = '{{colors.outline.default.hex}}' })
  hi('SignColumn',              { bg = 'NONE' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container.default.hex}}' })
  hi('FloatBorder',             { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('FloatTitle',              { fg = '{{colors.surface.default.hex}}',                bg = '{{colors.primary.default.hex}}', bold = true })

  -- Popup & Autocompletion Menu (Pmenu)
  hi('Pmenu',                   { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container.default.hex}}' })
  hi('PmenuSel',                { fg = '{{colors.surface.default.hex}}',                bg = '{{colors.primary.default.hex}}', bold = true })
  hi('PmenuSbar',               { bg = '{{colors.surface_container_high.default.hex}}' })
  hi('PmenuThumb',              { bg = '{{colors.outline.default.hex}}' })

  -- Diagnostics
  hi('DiagnosticError',         { fg = '{{colors.error.default.hex}}' })
  hi('DiagnosticWarn',          { fg = '{{colors.secondary.default.hex}}' })
  hi('DiagnosticInfo',          { fg = '{{colors.tertiary.default.hex}}' })
  hi('DiagnosticHint',          { fg = '{{colors.tertiary_fixed_dim.default.hex}}' })
  hi('DiagnosticUnderlineError',{ sp = '{{colors.error.default.hex}}',                 undercurl = true })
  hi('DiagnosticUnderlineWarn', { sp = '{{colors.secondary.default.hex}}',             undercurl = true })
  hi('DiagnosticUnderlineInfo', { sp = '{{colors.tertiary.default.hex}}',              undercurl = true })
  hi('DiagnosticUnderlineHint', { sp = '{{colors.tertiary_fixed_dim.default.hex}}',    undercurl = true })

  -- Git Signs & Diffs
  hi('GitSignsAdd',             { fg = '{{colors.primary.default.hex}}' })
  hi('GitSignsChange',          { fg = '{{colors.tertiary.default.hex}}' })
  hi('GitSignsDelete',          { fg = '{{colors.error.default.hex}}' })
  hi('DiffAdd',                 { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('DiffChange',              { fg = '{{colors.tertiary.default.hex}}',               bg = '{{colors.surface_container.default.hex}}' })
  hi('DiffDelete',              { fg = '{{colors.error.default.hex}}',                  bg = '{{colors.surface_container.default.hex}}' })
  hi('DiffText',                { fg = '{{colors.secondary.default.hex}}',              bg = '{{colors.surface_container_high.default.hex}}', bold = true })

  -- Indent Blankline
  hi('IblIndent',               { fg = '{{colors.surface_container.default.hex}}' })
  hi('IblScope',                { fg = '{{colors.outline.default.hex}}' })

  -- Bufferline
  hi('BufferLineFill',          { bg = '{{colors.surface.default.hex}}' })
  hi('BufferLineBackground',    { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('BufferLineBufferSelected',{ fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface.default.hex}}', bold = true })
  hi('BufferLineSeparator',     { fg = '{{colors.surface.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('BufferLineSeparatorSelected', { fg = '{{colors.surface.default.hex}}',            bg = '{{colors.surface.default.hex}}' })
  hi('BufferLineIndicatorSelected', { fg = '{{colors.primary.default.hex}}',            bg = '{{colors.surface.default.hex}}' })

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface.default.hex}}' })
  hi('TelescopeBorder',         { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface.default.hex}}' })
  hi('TelescopePromptNormal',   { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopePromptBorder',   { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopePromptPrefix',   { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopePromptCounter',  { fg = '{{colors.on_surface_variant.default.hex}}',     bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopePromptTitle',    { fg = '{{colors.surface.default.hex}}',                bg = '{{colors.primary.default.hex}}', bold = true })
  hi('TelescopePreviewTitle',   { fg = '{{colors.surface.default.hex}}',                bg = '{{colors.secondary.default.hex}}', bold = true })
  hi('TelescopeResultsTitle',   { fg = '{{colors.surface.default.hex}}',                bg = '{{colors.tertiary.default.hex}}', bold = true })
  hi('TelescopeSelection',      { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container_high.default.hex}}' })
  hi('TelescopeSelectionCaret', { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface_container_high.default.hex}}' })
  hi('TelescopeMatching',       { fg = '{{colors.secondary.default.hex}}',              bold = true })

  -- mini.pick
  hi('MiniPickNormal',          { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface.default.hex}}' })
  hi('MiniPickBorder',          { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface.default.hex}}' })
  hi('MiniPickPrompt',          { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface.default.hex}}' })
  hi('MiniPickPromptPrefix',    { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface.default.hex}}' })
  hi('MiniPickBorderText',      { fg = '{{colors.surface.default.hex}}',                bg = '{{colors.primary.default.hex}}' })
  hi('MiniPickMatchCurrent',    { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container_high.default.hex}}' })
  hi('MiniPickPromptCaret',     { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface_container_high.default.hex}}' })
  hi('MiniPickMatchRanges',     { fg = '{{colors.primary.default.hex}}',                bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
