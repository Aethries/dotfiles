-- Style policy lives in this repository; Noctalia replaces only color tokens.
-- Edit this template, not the generated lua/matugen.lua.
local M = {}

function M.setup()
  local ok, base16 = pcall(require, 'base16-colorscheme')
  if not ok then
    return
  end

  base16.setup({
    base00 = '#1a2123',
    base01 = '#2b373b',
    base02 = '#263236',
    base03 = '#5f6c6f',
    base04 = '#afb5b6',
    base05 = '#f2f3f3',
    base06 = '#f2f3f3',
    base07 = '#f2f3f3',
    base08 = '#fd4663',
    base09 = '#d8d2eb',
    base0A = '#d0d7ed',
    base0B = '#cde8f0',
    base0C = '#b3a7d8',
    base0D = '#a1d0de',
    base0E = '#a3b1dc',
    base0F = '#c8d0ea',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  local editor_background = vim.g.neovide and '#1a2123' or 'NONE'
  if vim.g.neovide then
    -- GUI cells need an explicit theme background, including empty/gutter areas.
    hi('Normal', { fg = '#f2f3f3', bg = editor_background })
    hi('NormalNC', { link = 'Normal' })
    hi('EndOfBuffer', { fg = '#5f6c6f', bg = editor_background })
    vim.g.neovide_title_background_color = '#1a2123'
    vim.g.neovide_title_text_color = '#f2f3f3'
  end

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '#263236', bg = 'NONE' })
  hi('VertSplit',               { fg = '#263236', bg = 'NONE' })
  hi('CursorLine',              { bg = '#2b373b' })
  hi('CursorLineNr',            { fg = '#d0d7ed',             bold = true })
  hi('LineNr',                  { fg = '#5f6c6f' })
  hi('SignColumn',              { bg = editor_background })

  -- NvimTree: retain the GUI theme surface; terminals inherit their background.
  hi('NvimTreeNormal',          { fg = '#f2f3f3',            bg = editor_background })
  hi('NvimTreeNormalNC',        { fg = '#f2f3f3',            bg = editor_background })
  hi('NvimTreeEndOfBuffer',     { fg = '#5f6c6f',               bg = editor_background })
  hi('NvimTreeWinSeparator',    { fg = '#5a6d73',       bg = 'NONE' })
  hi('NvimTreeCursorLine',      { bg = '#2b373b' })
  hi('NvimTreeRootFolder',      { fg = '#cde8f0',               bold = true })
  hi('NvimTreeFolderName',      { fg = '#afb5b6' })
  hi('NvimTreeOpenedFolderName',{ fg = '#f2f3f3',            bold = true })
  hi('NvimTreeFolderIcon',      { fg = '#d8d2eb' })
  hi('NvimTreeOpenedFolderIcon',{ fg = '#d0d7ed' })
  hi('NvimTreeIndentMarker',    { fg = '#5f6c6f' })
  hi('NvimTreeGitDeletedIcon',  { fg = '#fd4663' })
  hi('NvimTreeGitDirtyIcon',    { fg = '#d0d7ed' })
  hi('NvimTreeGitIgnoredIcon',  { fg = '#5f6c6f' })
  hi('NvimTreeGitMergeIcon',    { fg = '#d8d2eb' })
  hi('NvimTreeGitNewIcon',      { fg = '#cde8f0' })
  hi('NvimTreeGitRenamedIcon',  { fg = '#b3a7d8' })
  hi('NvimTreeGitStagedIcon',   { fg = '#cde8f0' })
  hi('NvimTreeGitFileDeletedHL',{ fg = '#fd4663' })
  hi('NvimTreeGitFileDirtyHL',  { fg = '#d0d7ed' })
  hi('NvimTreeGitFileIgnoredHL',{ fg = '#5f6c6f' })
  hi('NvimTreeGitFileMergeHL',  { fg = '#d8d2eb' })
  hi('NvimTreeGitFileNewHL',    { fg = '#cde8f0' })
  hi('NvimTreeGitFileRenamedHL',{ fg = '#b3a7d8' })
  hi('NvimTreeGitFileStagedHL', { fg = '#cde8f0' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '#f2f3f3',             bg = '#2b373b' })
  hi('FloatBorder',             { fg = '#5f6c6f',                bg = '#2b373b' })
  hi('FloatTitle',              { fg = '#1b2122',                bg = '#cde8f0', bold = true })

  -- Dialogs must not inherit the transparent Normal background.
  for _, group in ipairs({ 'NoiceCmdlinePopup', 'NoiceConfirm', 'NoiceMini', 'WhichKeyNormal' }) do
    hi(group, { link = 'NormalFloat' })
  end
  for _, group in ipairs({ 'NoiceCmdlinePopupBorder', 'NoiceCmdlinePopupBorderSearch', 'NoiceConfirmBorder', 'WhichKeyBorder' }) do
    hi(group, { link = 'FloatBorder' })
  end
  for level, color in pairs({
    ERROR = '#fd4663', WARN = '#d0d7ed',
    INFO = '#d8d2eb', DEBUG = '#5f6c6f',
    TRACE = '#cde8f0',
  }) do
    hi('Notify' .. level .. 'Body', { link = 'NormalFloat' })
    hi('Notify' .. level .. 'Border', { fg = color, bg = '#2b373b' })
    hi('Notify' .. level .. 'Icon', { link = 'Notify' .. level .. 'Border' })
    hi('Notify' .. level .. 'Title', { link = 'Notify' .. level .. 'Border' })
  end

  -- Popup & Autocompletion Menu (Pmenu)
  hi('Pmenu',                   { fg = '#f2f3f3',             bg = '#2b373b' })
  hi('PmenuSel',                { fg = '#1b2122',                bg = '#cde8f0', bold = true })
  hi('PmenuSbar',               { bg = '#263236' })
  hi('PmenuThumb',              { bg = '#5f6c6f' })

  -- Diagnostics
  hi('DiagnosticError',         { fg = '#fd4663' })
  hi('DiagnosticWarn',          { fg = '#d0d7ed' })
  hi('DiagnosticInfo',          { fg = '#d8d2eb' })
  hi('DiagnosticHint',          { fg = '#b3a7d8' })
  hi('DiagnosticUnderlineError',{ sp = '#fd4663',                 undercurl = true })
  hi('DiagnosticUnderlineWarn', { sp = '#d0d7ed',             undercurl = true })
  hi('DiagnosticUnderlineInfo', { sp = '#d8d2eb',              undercurl = true })
  hi('DiagnosticUnderlineHint', { sp = '#b3a7d8',    undercurl = true })

  -- Git Signs & Diffs
  hi('GitSignsAdd',             { fg = '#cde8f0' })
  hi('GitSignsChange',          { fg = '#d8d2eb' })
  hi('GitSignsDelete',          { fg = '#fd4663' })
  hi('DiffAdd',                 { fg = '#cde8f0',                bg = '#2b373b' })
  hi('DiffChange',              { fg = '#d8d2eb',               bg = '#2b373b' })
  hi('DiffDelete',              { fg = '#fd4663',                  bg = '#2b373b' })
  hi('DiffText',                { fg = '#d0d7ed',              bg = '#263236', bold = true })

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
  hi('IblIndent',               { fg = '#2b373b' })
  hi('IblScope',                { fg = '#5f6c6f' })

  -- Bufferline: one opaque surface, quiet inactive names, an accented selection.
  hi('BufferLineFill',          { bg = '#1a2123' })
  hi('BufferLineBackground',    { fg = '#5f6c6f', bg = '#1a2123' })
  hi('BufferLineBufferVisible', { fg = '#f2f3f3', bg = '#1a2123' })
  hi('BufferLineBufferSelected',{ fg = '#f2f3f3', bg = '#2b373b', bold = true })
  for _, group in ipairs({ 'BufferLineSeparator', 'BufferLineSeparatorVisible', 'BufferLineSeparatorSelected' }) do
    hi(group, { fg = '#1a2123', bg = '#1a2123' })
  end
  for _, part in ipairs({ 'Duplicate', 'CloseButton', 'Modified', 'Indicator' }) do
    hi('BufferLine' .. part, { fg = '#5f6c6f', bg = '#1a2123' })
    hi('BufferLine' .. part .. 'Visible', { fg = '#5f6c6f', bg = '#1a2123' })
    hi('BufferLine' .. part .. 'Selected', { fg = '#cde8f0', bg = '#2b373b' })
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f2f3f3',             bg = '#2b373b' })
  hi('TelescopeBorder',         { fg = '#5f6c6f',                bg = '#2b373b' })
  hi('TelescopeResultsNormal',  { link = 'TelescopeNormal' })
  hi('TelescopeResultsBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePreviewNormal',  { link = 'TelescopeNormal' })
  hi('TelescopePreviewBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePromptNormal',   { fg = '#f2f3f3',             bg = '#2b373b' })
  hi('TelescopePromptBorder',   { fg = '#5f6c6f',                bg = '#2b373b' })
  hi('TelescopePromptPrefix',   { fg = '#cde8f0',                bg = '#2b373b' })
  hi('TelescopePromptCounter',  { fg = '#afb5b6',     bg = '#2b373b' })
  hi('TelescopePromptTitle',    { fg = '#1b2122',                bg = '#cde8f0', bold = true })
  hi('TelescopePreviewTitle',   { fg = '#1b2122',                bg = '#d0d7ed', bold = true })
  hi('TelescopeResultsTitle',   { fg = '#1b2122',                bg = '#d8d2eb', bold = true })
  hi('TelescopeSelection',      { fg = '#f2f3f3',             bg = '#263236' })
  hi('TelescopeSelectionCaret', { fg = '#cde8f0',                bg = '#263236' })
  hi('TelescopeMatching',       { fg = '#d0d7ed',              bold = true })

  -- Flash.nvim: underline the current match; reserve filled primary for jump keys.
  hi('FlashMatch',   { link = 'TelescopeSelection' })
  hi('FlashCurrent', { fg = '#d0d7ed', bg = '#263236', bold = true, underline = true })
  hi('FlashLabel',   { fg = '#1b2122', bg = '#cde8f0', bold = true, nocombine = true })

  -- mini.pick
  hi('MiniPickNormal',          { fg = '#f2f3f3',             bg = '#1a2123' })
  hi('MiniPickBorder',          { fg = '#5f6c6f',                bg = '#1a2123' })
  hi('MiniPickPrompt',          { fg = '#f2f3f3',             bg = '#1a2123' })
  hi('MiniPickPromptPrefix',    { fg = '#cde8f0',                bg = '#1a2123' })
  hi('MiniPickBorderText',      { fg = '#1b2122',                bg = '#cde8f0' })
  hi('MiniPickMatchCurrent',    { fg = '#f2f3f3',             bg = '#263236' })
  hi('MiniPickPromptCaret',     { fg = '#cde8f0',                bg = '#263236' })
  hi('MiniPickMatchRanges',     { fg = '#cde8f0',                bold = true })

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
