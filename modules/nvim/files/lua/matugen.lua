-- Style policy lives in this repository; Noctalia replaces only color tokens.
-- Edit this template, not the generated lua/matugen.lua.
local M = {}

function M.setup()
  local ok, base16 = pcall(require, 'base16-colorscheme')
  if not ok then
    return
  end

  base16.setup({
    base00 = '#282828',
    base01 = '#3c3836',
    base02 = '#474240',
    base03 = '#76706c',
    base04 = '#ebdbb2',
    base05 = '#fbf1c7',
    base06 = '#fbf1c7',
    base07 = '#fbf1c7',
    base08 = '#fb4934',
    base09 = '#83a598',
    base0A = '#fabd2f',
    base0B = '#b8bb26',
    base0C = '#96e9c9',
    base0D = '#e8e995',
    base0E = '#fcd782',
    base0F = '#fde7b4',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  local editor_background = vim.g.neovide and '#282828' or 'NONE'
  if vim.g.neovide then
    -- GUI cells need an explicit theme background, including empty/gutter areas.
    hi('Normal', { fg = '#fbf1c7', bg = editor_background })
    hi('NormalNC', { link = 'Normal' })
    hi('EndOfBuffer', { fg = '#76706c', bg = editor_background })
    vim.g.neovide_title_background_color = '#282828'
    vim.g.neovide_title_text_color = '#fbf1c7'
  end

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '#474240', bg = 'NONE' })
  hi('VertSplit',               { fg = '#474240', bg = 'NONE' })
  hi('CursorLine',              { bg = '#3c3836' })
  hi('CursorLineNr',            { fg = '#fabd2f',             bold = true })
  hi('LineNr',                  { fg = '#76706c' })
  hi('SignColumn',              { bg = editor_background })

  -- NvimTree: retain the GUI theme surface; terminals inherit their background.
  hi('NvimTreeNormal',          { fg = '#fbf1c7',            bg = editor_background })
  hi('NvimTreeNormalNC',        { fg = '#fbf1c7',            bg = editor_background })
  hi('NvimTreeEndOfBuffer',     { fg = '#76706c',               bg = editor_background })
  hi('NvimTreeWinSeparator',    { fg = '#4e4a47',       bg = 'NONE' })
  hi('NvimTreeCursorLine',      { bg = '#3c3836' })
  hi('NvimTreeRootFolder',      { fg = '#b8bb26',               bold = true })
  hi('NvimTreeFolderName',      { fg = '#ebdbb2' })
  hi('NvimTreeOpenedFolderName',{ fg = '#fbf1c7',            bold = true })
  hi('NvimTreeFolderIcon',      { fg = '#83a598' })
  hi('NvimTreeOpenedFolderIcon',{ fg = '#fabd2f' })
  hi('NvimTreeIndentMarker',    { fg = '#76706c' })
  hi('NvimTreeGitDeletedIcon',  { fg = '#fb4934' })
  hi('NvimTreeGitDirtyIcon',    { fg = '#fabd2f' })
  hi('NvimTreeGitIgnoredIcon',  { fg = '#76706c' })
  hi('NvimTreeGitMergeIcon',    { fg = '#83a598' })
  hi('NvimTreeGitNewIcon',      { fg = '#b8bb26' })
  hi('NvimTreeGitRenamedIcon',  { fg = '#96e9c9' })
  hi('NvimTreeGitStagedIcon',   { fg = '#b8bb26' })
  hi('NvimTreeGitFileDeletedHL',{ fg = '#fb4934' })
  hi('NvimTreeGitFileDirtyHL',  { fg = '#fabd2f' })
  hi('NvimTreeGitFileIgnoredHL',{ fg = '#76706c' })
  hi('NvimTreeGitFileMergeHL',  { fg = '#83a598' })
  hi('NvimTreeGitFileNewHL',    { fg = '#b8bb26' })
  hi('NvimTreeGitFileRenamedHL',{ fg = '#96e9c9' })
  hi('NvimTreeGitFileStagedHL', { fg = '#b8bb26' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '#fbf1c7',             bg = '#3c3836' })
  hi('FloatBorder',             { fg = '#76706c',                bg = '#3c3836' })
  hi('FloatTitle',              { fg = '#282828',                bg = '#b8bb26', bold = true })

  -- Dialogs must not inherit the transparent Normal background.
  for _, group in ipairs({ 'NoiceCmdlinePopup', 'NoiceConfirm', 'NoiceMini', 'WhichKeyNormal' }) do
    hi(group, { link = 'NormalFloat' })
  end
  for _, group in ipairs({ 'NoiceCmdlinePopupBorder', 'NoiceCmdlinePopupBorderSearch', 'NoiceConfirmBorder', 'WhichKeyBorder' }) do
    hi(group, { link = 'FloatBorder' })
  end
  for level, color in pairs({
    ERROR = '#fb4934', WARN = '#fabd2f',
    INFO = '#83a598', DEBUG = '#76706c',
    TRACE = '#b8bb26',
  }) do
    hi('Notify' .. level .. 'Body', { link = 'NormalFloat' })
    hi('Notify' .. level .. 'Border', { fg = color, bg = '#3c3836' })
    hi('Notify' .. level .. 'Icon', { link = 'Notify' .. level .. 'Border' })
    hi('Notify' .. level .. 'Title', { link = 'Notify' .. level .. 'Border' })
  end

  -- Popup & Autocompletion Menu (Pmenu)
  hi('Pmenu',                   { fg = '#fbf1c7',             bg = '#3c3836' })
  hi('PmenuSel',                { fg = '#282828',                bg = '#b8bb26', bold = true })
  hi('PmenuSbar',               { bg = '#474240' })
  hi('PmenuThumb',              { bg = '#76706c' })

  -- Diagnostics
  hi('DiagnosticError',         { fg = '#fb4934' })
  hi('DiagnosticWarn',          { fg = '#fabd2f' })
  hi('DiagnosticInfo',          { fg = '#83a598' })
  hi('DiagnosticHint',          { fg = '#96e9c9' })
  hi('DiagnosticUnderlineError',{ sp = '#fb4934',                 undercurl = true })
  hi('DiagnosticUnderlineWarn', { sp = '#fabd2f',             undercurl = true })
  hi('DiagnosticUnderlineInfo', { sp = '#83a598',              undercurl = true })
  hi('DiagnosticUnderlineHint', { sp = '#96e9c9',    undercurl = true })

  -- Git Signs & Diffs
  hi('GitSignsAdd',             { fg = '#b8bb26' })
  hi('GitSignsChange',          { fg = '#83a598' })
  hi('GitSignsDelete',          { fg = '#fb4934' })
  hi('DiffAdd',                 { fg = '#b8bb26',                bg = '#3c3836' })
  hi('DiffChange',              { fg = '#83a598',               bg = '#3c3836' })
  hi('DiffDelete',              { fg = '#fb4934',                  bg = '#3c3836' })
  hi('DiffText',                { fg = '#fabd2f',              bg = '#474240', bold = true })

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
  hi('IblIndent',               { fg = '#3c3836' })
  hi('IblScope',                { fg = '#76706c' })

  -- Bufferline: one opaque surface, quiet inactive names, an accented selection.
  hi('BufferLineFill',          { bg = '#282828' })
  hi('BufferLineBackground',    { fg = '#76706c', bg = '#282828' })
  hi('BufferLineBufferVisible', { fg = '#fbf1c7', bg = '#282828' })
  hi('BufferLineBufferSelected',{ fg = '#fbf1c7', bg = '#3c3836', bold = true })
  for _, group in ipairs({ 'BufferLineSeparator', 'BufferLineSeparatorVisible', 'BufferLineSeparatorSelected' }) do
    hi(group, { fg = '#282828', bg = '#282828' })
  end
  for _, part in ipairs({ 'Duplicate', 'CloseButton', 'Modified', 'Indicator' }) do
    hi('BufferLine' .. part, { fg = '#76706c', bg = '#282828' })
    hi('BufferLine' .. part .. 'Visible', { fg = '#76706c', bg = '#282828' })
    hi('BufferLine' .. part .. 'Selected', { fg = '#b8bb26', bg = '#3c3836' })
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#fbf1c7',             bg = '#3c3836' })
  hi('TelescopeBorder',         { fg = '#76706c',                bg = '#3c3836' })
  hi('TelescopeResultsNormal',  { link = 'TelescopeNormal' })
  hi('TelescopeResultsBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePreviewNormal',  { link = 'TelescopeNormal' })
  hi('TelescopePreviewBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePromptNormal',   { fg = '#fbf1c7',             bg = '#3c3836' })
  hi('TelescopePromptBorder',   { fg = '#76706c',                bg = '#3c3836' })
  hi('TelescopePromptPrefix',   { fg = '#b8bb26',                bg = '#3c3836' })
  hi('TelescopePromptCounter',  { fg = '#ebdbb2',     bg = '#3c3836' })
  hi('TelescopePromptTitle',    { fg = '#282828',                bg = '#b8bb26', bold = true })
  hi('TelescopePreviewTitle',   { fg = '#282828',                bg = '#fabd2f', bold = true })
  hi('TelescopeResultsTitle',   { fg = '#282828',                bg = '#83a598', bold = true })
  hi('TelescopeSelection',      { fg = '#fbf1c7',             bg = '#474240' })
  hi('TelescopeSelectionCaret', { fg = '#b8bb26',                bg = '#474240' })
  hi('TelescopeMatching',       { fg = '#fabd2f',              bold = true })

  -- Flash.nvim: underline the current match; reserve filled primary for jump keys.
  hi('FlashMatch',   { link = 'TelescopeSelection' })
  hi('FlashCurrent', { fg = '#fabd2f', bg = '#474240', bold = true, underline = true })
  hi('FlashLabel',   { fg = '#282828', bg = '#b8bb26', bold = true, nocombine = true })

  -- mini.pick
  hi('MiniPickNormal',          { fg = '#fbf1c7',             bg = '#282828' })
  hi('MiniPickBorder',          { fg = '#76706c',                bg = '#282828' })
  hi('MiniPickPrompt',          { fg = '#fbf1c7',             bg = '#282828' })
  hi('MiniPickPromptPrefix',    { fg = '#b8bb26',                bg = '#282828' })
  hi('MiniPickBorderText',      { fg = '#282828',                bg = '#b8bb26' })
  hi('MiniPickMatchCurrent',    { fg = '#fbf1c7',             bg = '#474240' })
  hi('MiniPickPromptCaret',     { fg = '#b8bb26',                bg = '#474240' })
  hi('MiniPickMatchRanges',     { fg = '#b8bb26',                bold = true })

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
