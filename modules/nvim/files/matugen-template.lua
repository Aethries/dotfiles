-- Style policy lives in this repository; Noctalia replaces only color tokens.
-- Edit this template, not the generated lua/matugen.lua.
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

  local editor_background = vim.g.neovide and '{{colors.surface.default.hex}}' or 'NONE'
  if vim.g.neovide then
    -- GUI cells need an explicit theme background, including empty/gutter areas.
    hi('Normal', { fg = '{{colors.on_surface.default.hex}}', bg = editor_background })
    hi('NormalNC', { link = 'Normal' })
    hi('EndOfBuffer', { fg = '{{colors.outline.default.hex}}', bg = editor_background })
    vim.g.neovide_title_background_color = '{{colors.surface.default.hex}}'
    vim.g.neovide_title_text_color = '{{colors.on_surface.default.hex}}'
  end

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '{{colors.surface_container_high.default.hex}}', bg = 'NONE' })
  hi('VertSplit',               { fg = '{{colors.surface_container_high.default.hex}}', bg = 'NONE' })
  hi('CursorLine',              { bg = '{{colors.surface_container.default.hex}}' })
  hi('CursorLineNr',            { fg = '{{colors.secondary.default.hex}}',             bold = true })
  hi('LineNr',                  { fg = '{{colors.outline.default.hex}}' })
  hi('SignColumn',              { bg = editor_background })

  -- NvimTree: retain the GUI theme surface; terminals inherit their background.
  hi('NvimTreeNormal',          { fg = '{{colors.on_surface.default.hex}}',            bg = editor_background })
  hi('NvimTreeNormalNC',        { fg = '{{colors.on_surface.default.hex}}',            bg = editor_background })
  hi('NvimTreeEndOfBuffer',     { fg = '{{colors.outline.default.hex}}',               bg = editor_background })
  hi('NvimTreeWinSeparator',    { fg = '{{colors.outline_variant.default.hex}}',       bg = 'NONE' })
  hi('NvimTreeCursorLine',      { bg = '{{colors.surface_container.default.hex}}' })
  hi('NvimTreeRootFolder',      { fg = '{{colors.primary.default.hex}}',               bold = true })
  hi('NvimTreeFolderName',      { fg = '{{colors.on_surface_variant.default.hex}}' })
  hi('NvimTreeOpenedFolderName',{ fg = '{{colors.on_surface.default.hex}}',            bold = true })
  hi('NvimTreeFolderIcon',      { fg = '{{colors.tertiary.default.hex}}' })
  hi('NvimTreeOpenedFolderIcon',{ fg = '{{colors.secondary.default.hex}}' })
  hi('NvimTreeIndentMarker',    { fg = '{{colors.outline.default.hex}}' })
  hi('NvimTreeGitDeletedIcon',  { fg = '{{colors.error.default.hex}}' })
  hi('NvimTreeGitDirtyIcon',    { fg = '{{colors.secondary.default.hex}}' })
  hi('NvimTreeGitIgnoredIcon',  { fg = '{{colors.outline.default.hex}}' })
  hi('NvimTreeGitMergeIcon',    { fg = '{{colors.tertiary.default.hex}}' })
  hi('NvimTreeGitNewIcon',      { fg = '{{colors.primary.default.hex}}' })
  hi('NvimTreeGitRenamedIcon',  { fg = '{{colors.tertiary_fixed_dim.default.hex}}' })
  hi('NvimTreeGitStagedIcon',   { fg = '{{colors.primary.default.hex}}' })
  hi('NvimTreeGitFileDeletedHL',{ fg = '{{colors.error.default.hex}}' })
  hi('NvimTreeGitFileDirtyHL',  { fg = '{{colors.secondary.default.hex}}' })
  hi('NvimTreeGitFileIgnoredHL',{ fg = '{{colors.outline.default.hex}}' })
  hi('NvimTreeGitFileMergeHL',  { fg = '{{colors.tertiary.default.hex}}' })
  hi('NvimTreeGitFileNewHL',    { fg = '{{colors.primary.default.hex}}' })
  hi('NvimTreeGitFileRenamedHL',{ fg = '{{colors.tertiary_fixed_dim.default.hex}}' })
  hi('NvimTreeGitFileStagedHL', { fg = '{{colors.primary.default.hex}}' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container.default.hex}}' })
  hi('FloatBorder',             { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('FloatTitle',              { fg = '{{colors.on_primary.default.hex}}',                bg = '{{colors.primary.default.hex}}', bold = true })

  -- Dialogs must not inherit the transparent Normal background.
  for _, group in ipairs({ 'NoiceCmdlinePopup', 'NoiceConfirm', 'NoiceMini', 'WhichKeyNormal' }) do
    hi(group, { link = 'NormalFloat' })
  end
  for _, group in ipairs({ 'NoiceCmdlinePopupBorder', 'NoiceCmdlinePopupBorderSearch', 'NoiceConfirmBorder', 'WhichKeyBorder' }) do
    hi(group, { link = 'FloatBorder' })
  end
  for level, color in pairs({
    ERROR = '{{colors.error.default.hex}}', WARN = '{{colors.secondary.default.hex}}',
    INFO = '{{colors.tertiary.default.hex}}', DEBUG = '{{colors.outline.default.hex}}',
    TRACE = '{{colors.primary.default.hex}}',
  }) do
    hi('Notify' .. level .. 'Body', { link = 'NormalFloat' })
    hi('Notify' .. level .. 'Border', { fg = color, bg = '{{colors.surface_container.default.hex}}' })
    hi('Notify' .. level .. 'Icon', { link = 'Notify' .. level .. 'Border' })
    hi('Notify' .. level .. 'Title', { link = 'Notify' .. level .. 'Border' })
  end

  -- Popup & Autocompletion Menu (Pmenu)
  hi('Pmenu',                   { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container.default.hex}}' })
  hi('PmenuSel',                { fg = '{{colors.on_primary.default.hex}}',                bg = '{{colors.primary.default.hex}}', bold = true })
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

  -- Source Control uses the Noctalia surfaces and semantic diff colors.
  hi('DiffviewNormal',           { link = 'NvimTreeNormal' })
  hi('DiffviewWinSeparator',     { link = 'NvimTreeWinSeparator' })
  hi('DiffviewFilePanelTitle',   { link = 'NvimTreeRootFolder' })
  hi('DiffviewFilePanelSelected',{ link = 'NvimTreeCursorLine' })
  hi('DiffviewFilePanelFileName',{ link = 'NvimTreeNormal' })
  hi('DiffviewFolderName',      { link = 'NvimTreeFolderName' })
  hi('DiffviewFolderSign',      { link = 'NvimTreeFolderIcon' })
  hi('DiffviewNonText',         { link = 'NvimTreeIndentMarker' })
  hi('DiffviewFilePanelCounter', { link = 'Comment' })
  hi('DiffviewFilePanelInsertions', { link = 'GitSignsAdd' })
  hi('DiffviewFilePanelDeletions',  { link = 'GitSignsDelete' })

  -- Indent Blankline
  hi('IblIndent',               { fg = '{{colors.surface_container.default.hex}}' })
  hi('IblScope',                { fg = '{{colors.outline.default.hex}}' })

  -- Bufferline: one opaque surface, quiet inactive names, an accented selection.
  hi('BufferLineFill',          { bg = '{{colors.surface.default.hex}}' })
  hi('BufferLineBackground',    { fg = '{{colors.outline.default.hex}}', bg = '{{colors.surface.default.hex}}' })
  hi('BufferLineBufferVisible', { fg = '{{colors.on_surface.default.hex}}', bg = '{{colors.surface.default.hex}}' })
  hi('BufferLineBufferSelected',{ fg = '{{colors.on_surface.default.hex}}', bg = '{{colors.surface_container.default.hex}}', bold = true })
  for _, group in ipairs({ 'BufferLineSeparator', 'BufferLineSeparatorVisible', 'BufferLineSeparatorSelected' }) do
    hi(group, { fg = '{{colors.surface.default.hex}}', bg = '{{colors.surface.default.hex}}' })
  end
  for _, part in ipairs({ 'Duplicate', 'CloseButton', 'Modified', 'Indicator' }) do
    hi('BufferLine' .. part, { fg = '{{colors.outline.default.hex}}', bg = '{{colors.surface.default.hex}}' })
    hi('BufferLine' .. part .. 'Visible', { fg = '{{colors.outline.default.hex}}', bg = '{{colors.surface.default.hex}}' })
    hi('BufferLine' .. part .. 'Selected', { fg = '{{colors.primary.default.hex}}', bg = '{{colors.surface_container.default.hex}}' })
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopeBorder',         { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopeResultsNormal',  { link = 'TelescopeNormal' })
  hi('TelescopeResultsBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePreviewNormal',  { link = 'TelescopeNormal' })
  hi('TelescopePreviewBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePromptNormal',   { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopePromptBorder',   { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopePromptPrefix',   { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopePromptCounter',  { fg = '{{colors.on_surface_variant.default.hex}}',     bg = '{{colors.surface_container.default.hex}}' })
  hi('TelescopePromptTitle',    { fg = '{{colors.on_primary.default.hex}}',                bg = '{{colors.primary.default.hex}}', bold = true })
  hi('TelescopePreviewTitle',   { fg = '{{colors.on_secondary.default.hex}}',                bg = '{{colors.secondary.default.hex}}', bold = true })
  hi('TelescopeResultsTitle',   { fg = '{{colors.on_tertiary.default.hex}}',                bg = '{{colors.tertiary.default.hex}}', bold = true })
  hi('TelescopeSelection',      { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container_high.default.hex}}' })
  hi('TelescopeSelectionCaret', { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface_container_high.default.hex}}' })
  hi('TelescopeMatching',       { fg = '{{colors.secondary.default.hex}}',              bold = true })

  -- Flash.nvim: underline the current match; reserve filled primary for jump keys.
  hi('FlashMatch',   { link = 'TelescopeSelection' })
  hi('FlashCurrent', { fg = '{{colors.secondary.default.hex}}', bg = '{{colors.surface_container_high.default.hex}}', bold = true, underline = true })
  hi('FlashLabel',   { fg = '{{colors.on_primary.default.hex}}', bg = '{{colors.primary.default.hex}}', bold = true, nocombine = true })

  -- mini.pick
  hi('MiniPickNormal',          { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface.default.hex}}' })
  hi('MiniPickBorder',          { fg = '{{colors.outline.default.hex}}',                bg = '{{colors.surface.default.hex}}' })
  hi('MiniPickPrompt',          { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface.default.hex}}' })
  hi('MiniPickPromptPrefix',    { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface.default.hex}}' })
  hi('MiniPickBorderText',      { fg = '{{colors.on_primary.default.hex}}',                bg = '{{colors.primary.default.hex}}' })
  hi('MiniPickMatchCurrent',    { fg = '{{colors.on_surface.default.hex}}',             bg = '{{colors.surface_container_high.default.hex}}' })
  hi('MiniPickPromptCaret',     { fg = '{{colors.primary.default.hex}}',                bg = '{{colors.surface_container_high.default.hex}}' })
  hi('MiniPickMatchRanges',     { fg = '{{colors.primary.default.hex}}',                bold = true })

  -- Rebuild generated icon colors after all Noctalia highlights are applied.
  if package.loaded['bufferline'] then
    local highlights = require('bufferline.highlights')
    highlights.set_all(require('bufferline.config').update_highlights())
    highlights.reset_icon_hl_cache()
  end
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
