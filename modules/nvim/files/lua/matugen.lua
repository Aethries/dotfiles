-- Style policy lives in this repository; Noctalia replaces only color tokens.
-- Edit this template, not the generated lua/matugen.lua.
local M = {}

function M.setup()
  local ok, base16 = pcall(require, 'base16-colorscheme')
  if not ok then
    return
  end

  base16.setup({
    base00 = '#231a1d',
    base01 = '#3b2b30',
    base02 = '#35272b',
    base03 = '#736368',
    base04 = '#b6afb1',
    base05 = '#f3f2f2',
    base06 = '#f3f2f2',
    base07 = '#f3f2f2',
    base08 = '#e77896',
    base09 = '#c1b7a2',
    base0A = '#c4a59f',
    base0B = '#c99aa9',
    base0C = '#d0c5af',
    base0D = '#d3acb8',
    base0E = '#d0b4af',
    base0F = '#e4d1cd',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  local editor_background = vim.g.neovide and '#231a1d' or 'NONE'
  if vim.g.neovide then
    -- GUI cells need an explicit theme background, including empty/gutter areas.
    hi('Normal', { fg = '#f3f2f2', bg = editor_background })
    hi('NormalNC', { link = 'Normal' })
    hi('EndOfBuffer', { fg = '#736368', bg = editor_background })
    vim.g.neovide_title_background_color = '#231a1d'
    vim.g.neovide_title_text_color = '#f3f2f2'
  end

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '#35272b', bg = 'NONE' })
  hi('VertSplit',               { fg = '#35272b', bg = 'NONE' })
  hi('CursorLine',              { bg = '#3b2b30' })
  hi('CursorLineNr',            { fg = '#c4a59f',             bold = true })
  hi('LineNr',                  { fg = '#736368' })
  hi('SignColumn',              { bg = editor_background })

  -- NvimTree: retain the GUI theme surface; terminals inherit their background.
  hi('NvimTreeNormal',          { fg = '#f3f2f2',            bg = editor_background })
  hi('NvimTreeNormalNC',        { fg = '#f3f2f2',            bg = editor_background })
  hi('NvimTreeEndOfBuffer',     { fg = '#736368',               bg = editor_background })
  hi('NvimTreeWinSeparator',    { fg = '#796169',       bg = 'NONE' })
  hi('NvimTreeCursorLine',      { bg = '#3b2b30' })
  hi('NvimTreeRootFolder',      { fg = '#c99aa9',               bold = true })
  hi('NvimTreeFolderName',      { fg = '#b6afb1' })
  hi('NvimTreeOpenedFolderName',{ fg = '#f3f2f2',            bold = true })
  hi('NvimTreeFolderIcon',      { fg = '#c1b7a2' })
  hi('NvimTreeOpenedFolderIcon',{ fg = '#c4a59f' })
  hi('NvimTreeIndentMarker',    { fg = '#736368' })
  hi('NvimTreeGitDeletedIcon',  { fg = '#e77896' })
  hi('NvimTreeGitDirtyIcon',    { fg = '#c4a59f' })
  hi('NvimTreeGitIgnoredIcon',  { fg = '#736368' })
  hi('NvimTreeGitMergeIcon',    { fg = '#c1b7a2' })
  hi('NvimTreeGitNewIcon',      { fg = '#c99aa9' })
  hi('NvimTreeGitRenamedIcon',  { fg = '#d0c5af' })
  hi('NvimTreeGitStagedIcon',   { fg = '#c99aa9' })
  hi('NvimTreeGitFileDeletedHL',{ fg = '#e77896' })
  hi('NvimTreeGitFileDirtyHL',  { fg = '#c4a59f' })
  hi('NvimTreeGitFileIgnoredHL',{ fg = '#736368' })
  hi('NvimTreeGitFileMergeHL',  { fg = '#c1b7a2' })
  hi('NvimTreeGitFileNewHL',    { fg = '#c99aa9' })
  hi('NvimTreeGitFileRenamedHL',{ fg = '#d0c5af' })
  hi('NvimTreeGitFileStagedHL', { fg = '#c99aa9' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '#f3f2f2',             bg = '#3b2b30' })
  hi('FloatBorder',             { fg = '#736368',                bg = '#3b2b30' })
  hi('FloatTitle',              { fg = '#221b1d',                bg = '#c99aa9', bold = true })

  -- Dialogs must not inherit the transparent Normal background.
  for _, group in ipairs({ 'NoiceCmdlinePopup', 'NoiceConfirm', 'NoiceMini', 'WhichKeyNormal' }) do
    hi(group, { link = 'NormalFloat' })
  end
  for _, group in ipairs({ 'NoiceCmdlinePopupBorder', 'NoiceCmdlinePopupBorderSearch', 'NoiceConfirmBorder', 'WhichKeyBorder' }) do
    hi(group, { link = 'FloatBorder' })
  end
  for level, color in pairs({
    ERROR = '#e77896', WARN = '#c4a59f',
    INFO = '#c1b7a2', DEBUG = '#736368',
    TRACE = '#c99aa9',
  }) do
    hi('Notify' .. level .. 'Body', { link = 'NormalFloat' })
    hi('Notify' .. level .. 'Border', { fg = color, bg = '#3b2b30' })
    hi('Notify' .. level .. 'Icon', { link = 'Notify' .. level .. 'Border' })
    hi('Notify' .. level .. 'Title', { link = 'Notify' .. level .. 'Border' })
  end

  -- Popup & Autocompletion Menu (Pmenu)
  hi('Pmenu',                   { fg = '#f3f2f2',             bg = '#3b2b30' })
  hi('PmenuSel',                { fg = '#221b1d',                bg = '#c99aa9', bold = true })
  hi('PmenuSbar',               { bg = '#35272b' })
  hi('PmenuThumb',              { bg = '#736368' })

  -- Diagnostics
  hi('DiagnosticError',         { fg = '#e77896' })
  hi('DiagnosticWarn',          { fg = '#c4a59f' })
  hi('DiagnosticInfo',          { fg = '#c1b7a2' })
  hi('DiagnosticHint',          { fg = '#d0c5af' })
  hi('DiagnosticUnderlineError',{ sp = '#e77896',                 undercurl = true })
  hi('DiagnosticUnderlineWarn', { sp = '#c4a59f',             undercurl = true })
  hi('DiagnosticUnderlineInfo', { sp = '#c1b7a2',              undercurl = true })
  hi('DiagnosticUnderlineHint', { sp = '#d0c5af',    undercurl = true })

  -- Git Signs & Diffs
  hi('GitSignsAdd',             { fg = '#c99aa9' })
  hi('GitSignsChange',          { fg = '#c1b7a2' })
  hi('GitSignsDelete',          { fg = '#e77896' })
  hi('DiffAdd',                 { fg = '#c99aa9',                bg = '#3b2b30' })
  hi('DiffChange',              { fg = '#c1b7a2',               bg = '#3b2b30' })
  hi('DiffDelete',              { fg = '#e77896',                  bg = '#3b2b30' })
  hi('DiffText',                { fg = '#c4a59f',              bg = '#35272b', bold = true })

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
  hi('IblIndent',               { fg = '#3b2b30' })
  hi('IblScope',                { fg = '#736368' })

  -- Bufferline: one opaque surface, quiet inactive names, an accented selection.
  hi('BufferLineFill',          { bg = '#231a1d' })
  hi('BufferLineBackground',    { fg = '#736368', bg = '#231a1d' })
  hi('BufferLineBufferVisible', { fg = '#f3f2f2', bg = '#231a1d' })
  hi('BufferLineBufferSelected',{ fg = '#f3f2f2', bg = '#3b2b30', bold = true })
  for _, group in ipairs({ 'BufferLineSeparator', 'BufferLineSeparatorVisible', 'BufferLineSeparatorSelected' }) do
    hi(group, { fg = '#231a1d', bg = '#231a1d' })
  end
  for _, part in ipairs({ 'Duplicate', 'CloseButton', 'Modified', 'Indicator' }) do
    hi('BufferLine' .. part, { fg = '#736368', bg = '#231a1d' })
    hi('BufferLine' .. part .. 'Visible', { fg = '#736368', bg = '#231a1d' })
    hi('BufferLine' .. part .. 'Selected', { fg = '#c99aa9', bg = '#3b2b30' })
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f3f2f2',             bg = '#3b2b30' })
  hi('TelescopeBorder',         { fg = '#736368',                bg = '#3b2b30' })
  hi('TelescopeResultsNormal',  { link = 'TelescopeNormal' })
  hi('TelescopeResultsBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePreviewNormal',  { link = 'TelescopeNormal' })
  hi('TelescopePreviewBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePromptNormal',   { fg = '#f3f2f2',             bg = '#3b2b30' })
  hi('TelescopePromptBorder',   { fg = '#736368',                bg = '#3b2b30' })
  hi('TelescopePromptPrefix',   { fg = '#c99aa9',                bg = '#3b2b30' })
  hi('TelescopePromptCounter',  { fg = '#b6afb1',     bg = '#3b2b30' })
  hi('TelescopePromptTitle',    { fg = '#221b1d',                bg = '#c99aa9', bold = true })
  hi('TelescopePreviewTitle',   { fg = '#221b1d',                bg = '#c4a59f', bold = true })
  hi('TelescopeResultsTitle',   { fg = '#221b1d',                bg = '#c1b7a2', bold = true })
  hi('TelescopeSelection',      { fg = '#f3f2f2',             bg = '#35272b' })
  hi('TelescopeSelectionCaret', { fg = '#c99aa9',                bg = '#35272b' })
  hi('TelescopeMatching',       { fg = '#c4a59f',              bold = true })

  -- Flash.nvim: underline the current match; reserve filled primary for jump keys.
  hi('FlashMatch',   { link = 'TelescopeSelection' })
  hi('FlashCurrent', { fg = '#c4a59f', bg = '#35272b', bold = true, underline = true })
  hi('FlashLabel',   { fg = '#221b1d', bg = '#c99aa9', bold = true, nocombine = true })

  -- mini.pick
  hi('MiniPickNormal',          { fg = '#f3f2f2',             bg = '#231a1d' })
  hi('MiniPickBorder',          { fg = '#736368',                bg = '#231a1d' })
  hi('MiniPickPrompt',          { fg = '#f3f2f2',             bg = '#231a1d' })
  hi('MiniPickPromptPrefix',    { fg = '#c99aa9',                bg = '#231a1d' })
  hi('MiniPickBorderText',      { fg = '#221b1d',                bg = '#c99aa9' })
  hi('MiniPickMatchCurrent',    { fg = '#f3f2f2',             bg = '#35272b' })
  hi('MiniPickPromptCaret',     { fg = '#c99aa9',                bg = '#35272b' })
  hi('MiniPickMatchRanges',     { fg = '#c99aa9',                bold = true })

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
