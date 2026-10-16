-- Style policy lives in this repository; Noctalia replaces only color tokens.
-- Edit this template, not the generated lua/matugen.lua.
local M = {}

function M.setup()
  local ok, base16 = pcall(require, 'base16-colorscheme')
  if not ok then
    return
  end

  base16.setup({
    base00 = '#1a1f23',
    base01 = '#2b333b',
    base02 = '#262e36',
    base03 = '#626a72',
    base04 = '#afb2b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#9970c2',
    base0A = '#6b6bc7',
    base0B = '#75a5d7',
    base0C = '#bfa6d9',
    base0D = '#a1bfde',
    base0E = '#a3a3dc',
    base0F = '#c8c8ea',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  local editor_background = vim.g.neovide and '#1a1f23' or 'NONE'
  if vim.g.neovide then
    -- GUI cells need an explicit theme background, including empty/gutter areas.
    hi('Normal', { fg = '#f2f2f3', bg = editor_background })
    hi('NormalNC', { link = 'Normal' })
    hi('EndOfBuffer', { fg = '#626a72', bg = editor_background })
    vim.g.neovide_title_background_color = '#1a1f23'
    vim.g.neovide_title_text_color = '#f2f2f3'
  end

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '#262e36', bg = 'NONE' })
  hi('VertSplit',               { fg = '#262e36', bg = 'NONE' })
  hi('CursorLine',              { bg = '#2b333b' })
  hi('CursorLineNr',            { fg = '#6b6bc7',             bold = true })
  hi('LineNr',                  { fg = '#626a72' })
  hi('SignColumn',              { bg = editor_background })

  -- NvimTree: retain the GUI theme surface; terminals inherit their background.
  hi('NvimTreeNormal',          { fg = '#f2f2f3',            bg = editor_background })
  hi('NvimTreeNormalNC',        { fg = '#f2f2f3',            bg = editor_background })
  hi('NvimTreeEndOfBuffer',     { fg = '#626a72',               bg = editor_background })
  hi('NvimTreeWinSeparator',    { fg = '#5e6a76',       bg = 'NONE' })
  hi('NvimTreeCursorLine',      { bg = '#2b333b' })
  hi('NvimTreeRootFolder',      { fg = '#75a5d7',               bold = true })
  hi('NvimTreeFolderName',      { fg = '#afb2b6' })
  hi('NvimTreeOpenedFolderName',{ fg = '#f2f2f3',            bold = true })
  hi('NvimTreeFolderIcon',      { fg = '#9970c2' })
  hi('NvimTreeOpenedFolderIcon',{ fg = '#6b6bc7' })
  hi('NvimTreeIndentMarker',    { fg = '#626a72' })
  hi('NvimTreeGitDeletedIcon',  { fg = '#fd4663' })
  hi('NvimTreeGitDirtyIcon',    { fg = '#6b6bc7' })
  hi('NvimTreeGitIgnoredIcon',  { fg = '#626a72' })
  hi('NvimTreeGitMergeIcon',    { fg = '#9970c2' })
  hi('NvimTreeGitNewIcon',      { fg = '#75a5d7' })
  hi('NvimTreeGitRenamedIcon',  { fg = '#bfa6d9' })
  hi('NvimTreeGitStagedIcon',   { fg = '#75a5d7' })
  hi('NvimTreeGitFileDeletedHL',{ fg = '#fd4663' })
  hi('NvimTreeGitFileDirtyHL',  { fg = '#6b6bc7' })
  hi('NvimTreeGitFileIgnoredHL',{ fg = '#626a72' })
  hi('NvimTreeGitFileMergeHL',  { fg = '#9970c2' })
  hi('NvimTreeGitFileNewHL',    { fg = '#75a5d7' })
  hi('NvimTreeGitFileRenamedHL',{ fg = '#bfa6d9' })
  hi('NvimTreeGitFileStagedHL', { fg = '#75a5d7' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '#f2f2f3',             bg = '#2b333b' })
  hi('FloatBorder',             { fg = '#626a72',                bg = '#2b333b' })
  hi('FloatTitle',              { fg = '#1b1f22',                bg = '#75a5d7', bold = true })

  -- Dialogs must not inherit the transparent Normal background.
  for _, group in ipairs({ 'NoiceCmdlinePopup', 'NoiceConfirm', 'NoiceMini', 'WhichKeyNormal' }) do
    hi(group, { link = 'NormalFloat' })
  end
  for _, group in ipairs({ 'NoiceCmdlinePopupBorder', 'NoiceCmdlinePopupBorderSearch', 'NoiceConfirmBorder', 'WhichKeyBorder' }) do
    hi(group, { link = 'FloatBorder' })
  end
  for level, color in pairs({
    ERROR = '#fd4663', WARN = '#6b6bc7',
    INFO = '#9970c2', DEBUG = '#626a72',
    TRACE = '#75a5d7',
  }) do
    hi('Notify' .. level .. 'Body', { link = 'NormalFloat' })
    hi('Notify' .. level .. 'Border', { fg = color, bg = '#2b333b' })
    hi('Notify' .. level .. 'Icon', { link = 'Notify' .. level .. 'Border' })
    hi('Notify' .. level .. 'Title', { link = 'Notify' .. level .. 'Border' })
  end

  -- Popup & Autocompletion Menu (Pmenu)
  hi('Pmenu',                   { fg = '#f2f2f3',             bg = '#2b333b' })
  hi('PmenuSel',                { fg = '#1b1f22',                bg = '#75a5d7', bold = true })
  hi('PmenuSbar',               { bg = '#262e36' })
  hi('PmenuThumb',              { bg = '#626a72' })

  -- Diagnostics
  hi('DiagnosticError',         { fg = '#fd4663' })
  hi('DiagnosticWarn',          { fg = '#6b6bc7' })
  hi('DiagnosticInfo',          { fg = '#9970c2' })
  hi('DiagnosticHint',          { fg = '#bfa6d9' })
  hi('DiagnosticUnderlineError',{ sp = '#fd4663',                 undercurl = true })
  hi('DiagnosticUnderlineWarn', { sp = '#6b6bc7',             undercurl = true })
  hi('DiagnosticUnderlineInfo', { sp = '#9970c2',              undercurl = true })
  hi('DiagnosticUnderlineHint', { sp = '#bfa6d9',    undercurl = true })

  -- Git Signs & Diffs
  hi('GitSignsAdd',             { fg = '#75a5d7' })
  hi('GitSignsChange',          { fg = '#9970c2' })
  hi('GitSignsDelete',          { fg = '#fd4663' })
  hi('DiffAdd',                 { fg = '#75a5d7',                bg = '#2b333b' })
  hi('DiffChange',              { fg = '#9970c2',               bg = '#2b333b' })
  hi('DiffDelete',              { fg = '#fd4663',                  bg = '#2b333b' })
  hi('DiffText',                { fg = '#6b6bc7',              bg = '#262e36', bold = true })

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
  hi('IblIndent',               { fg = '#2b333b' })
  hi('IblScope',                { fg = '#626a72' })

  -- Bufferline: one opaque surface, quiet inactive names, an accented selection.
  hi('BufferLineFill',          { bg = '#1a1f23' })
  hi('BufferLineBackground',    { fg = '#626a72', bg = '#1a1f23' })
  hi('BufferLineBufferVisible', { fg = '#f2f2f3', bg = '#1a1f23' })
  hi('BufferLineBufferSelected',{ fg = '#f2f2f3', bg = '#2b333b', bold = true })
  for _, group in ipairs({ 'BufferLineSeparator', 'BufferLineSeparatorVisible', 'BufferLineSeparatorSelected' }) do
    hi(group, { fg = '#1a1f23', bg = '#1a1f23' })
  end
  for _, part in ipairs({ 'Duplicate', 'CloseButton', 'Modified', 'Indicator' }) do
    hi('BufferLine' .. part, { fg = '#626a72', bg = '#1a1f23' })
    hi('BufferLine' .. part .. 'Visible', { fg = '#626a72', bg = '#1a1f23' })
    hi('BufferLine' .. part .. 'Selected', { fg = '#75a5d7', bg = '#2b333b' })
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f2f2f3',             bg = '#2b333b' })
  hi('TelescopeBorder',         { fg = '#626a72',                bg = '#2b333b' })
  hi('TelescopeResultsNormal',  { link = 'TelescopeNormal' })
  hi('TelescopeResultsBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePreviewNormal',  { link = 'TelescopeNormal' })
  hi('TelescopePreviewBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',             bg = '#2b333b' })
  hi('TelescopePromptBorder',   { fg = '#626a72',                bg = '#2b333b' })
  hi('TelescopePromptPrefix',   { fg = '#75a5d7',                bg = '#2b333b' })
  hi('TelescopePromptCounter',  { fg = '#afb2b6',     bg = '#2b333b' })
  hi('TelescopePromptTitle',    { fg = '#1b1f22',                bg = '#75a5d7', bold = true })
  hi('TelescopePreviewTitle',   { fg = '#f9fdff',                bg = '#6b6bc7', bold = true })
  hi('TelescopeResultsTitle',   { fg = '#171b1d',                bg = '#9970c2', bold = true })
  hi('TelescopeSelection',      { fg = '#f2f2f3',             bg = '#262e36' })
  hi('TelescopeSelectionCaret', { fg = '#75a5d7',                bg = '#262e36' })
  hi('TelescopeMatching',       { fg = '#6b6bc7',              bold = true })

  -- Flash.nvim: underline the current match; reserve filled primary for jump keys.
  hi('FlashMatch',   { link = 'TelescopeSelection' })
  hi('FlashCurrent', { fg = '#6b6bc7', bg = '#262e36', bold = true, underline = true })
  hi('FlashLabel',   { fg = '#1b1f22', bg = '#75a5d7', bold = true, nocombine = true })

  -- mini.pick
  hi('MiniPickNormal',          { fg = '#f2f2f3',             bg = '#1a1f23' })
  hi('MiniPickBorder',          { fg = '#626a72',                bg = '#1a1f23' })
  hi('MiniPickPrompt',          { fg = '#f2f2f3',             bg = '#1a1f23' })
  hi('MiniPickPromptPrefix',    { fg = '#75a5d7',                bg = '#1a1f23' })
  hi('MiniPickBorderText',      { fg = '#1b1f22',                bg = '#75a5d7' })
  hi('MiniPickMatchCurrent',    { fg = '#f2f2f3',             bg = '#262e36' })
  hi('MiniPickPromptCaret',     { fg = '#75a5d7',                bg = '#262e36' })
  hi('MiniPickMatchRanges',     { fg = '#75a5d7',                bold = true })

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
