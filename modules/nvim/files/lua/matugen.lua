-- Style policy lives in this repository; Noctalia replaces only color tokens.
-- Edit this template, not the generated lua/matugen.lua.
local M = {}

function M.setup()
  local ok, base16 = pcall(require, 'base16-colorscheme')
  if not ok then
    return
  end

  base16.setup({
    base00 = '#1a1e23',
    base01 = '#2b323b',
    base02 = '#262d36',
    base03 = '#616971',
    base04 = '#afb2b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#9e70c2',
    base0A = '#706bc7',
    base0B = '#75a0d7',
    base0C = '#c2a6d9',
    base0D = '#a1bcde',
    base0E = '#a6a3dc',
    base0F = '#c9c8ea',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  local editor_background = vim.g.neovide and '#1a1e23' or 'NONE'
  if vim.g.neovide then
    -- GUI cells need an explicit theme background, including empty/gutter areas.
    hi('Normal', { fg = '#f2f2f3', bg = editor_background })
    hi('NormalNC', { link = 'Normal' })
    hi('EndOfBuffer', { fg = '#616971', bg = editor_background })
    vim.g.neovide_title_background_color = '#1a1e23'
    vim.g.neovide_title_text_color = '#f2f2f3'
  end

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '#262d36', bg = 'NONE' })
  hi('VertSplit',               { fg = '#262d36', bg = 'NONE' })
  hi('CursorLine',              { bg = '#2b323b' })
  hi('CursorLineNr',            { fg = '#706bc7',             bold = true })
  hi('LineNr',                  { fg = '#616971' })
  hi('SignColumn',              { bg = editor_background })

  -- NvimTree: retain the GUI theme surface; terminals inherit their background.
  hi('NvimTreeNormal',          { fg = '#f2f2f3',            bg = editor_background })
  hi('NvimTreeNormalNC',        { fg = '#f2f2f3',            bg = editor_background })
  hi('NvimTreeEndOfBuffer',     { fg = '#616971',               bg = editor_background })
  hi('NvimTreeWinSeparator',    { fg = '#5e6977',       bg = 'NONE' })
  hi('NvimTreeCursorLine',      { bg = '#2b323b' })
  hi('NvimTreeRootFolder',      { fg = '#75a0d7',               bold = true })
  hi('NvimTreeFolderName',      { fg = '#afb2b6' })
  hi('NvimTreeOpenedFolderName',{ fg = '#f2f2f3',            bold = true })
  hi('NvimTreeFolderIcon',      { fg = '#9e70c2' })
  hi('NvimTreeOpenedFolderIcon',{ fg = '#706bc7' })
  hi('NvimTreeIndentMarker',    { fg = '#616971' })
  hi('NvimTreeGitDeletedIcon',  { fg = '#fd4663' })
  hi('NvimTreeGitDirtyIcon',    { fg = '#706bc7' })
  hi('NvimTreeGitIgnoredIcon',  { fg = '#616971' })
  hi('NvimTreeGitMergeIcon',    { fg = '#9e70c2' })
  hi('NvimTreeGitNewIcon',      { fg = '#75a0d7' })
  hi('NvimTreeGitRenamedIcon',  { fg = '#c2a6d9' })
  hi('NvimTreeGitStagedIcon',   { fg = '#75a0d7' })
  hi('NvimTreeGitFileDeletedHL',{ fg = '#fd4663' })
  hi('NvimTreeGitFileDirtyHL',  { fg = '#706bc7' })
  hi('NvimTreeGitFileIgnoredHL',{ fg = '#616971' })
  hi('NvimTreeGitFileMergeHL',  { fg = '#9e70c2' })
  hi('NvimTreeGitFileNewHL',    { fg = '#75a0d7' })
  hi('NvimTreeGitFileRenamedHL',{ fg = '#c2a6d9' })
  hi('NvimTreeGitFileStagedHL', { fg = '#75a0d7' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '#f2f2f3',             bg = '#2b323b' })
  hi('FloatBorder',             { fg = '#616971',                bg = '#2b323b' })
  hi('FloatTitle',              { fg = '#1b1e22',                bg = '#75a0d7', bold = true })

  -- Dialogs must not inherit the transparent Normal background.
  for _, group in ipairs({ 'NoiceCmdlinePopup', 'NoiceConfirm', 'NoiceMini', 'WhichKeyNormal' }) do
    hi(group, { link = 'NormalFloat' })
  end
  for _, group in ipairs({ 'NoiceCmdlinePopupBorder', 'NoiceCmdlinePopupBorderSearch', 'NoiceConfirmBorder', 'WhichKeyBorder' }) do
    hi(group, { link = 'FloatBorder' })
  end
  for level, color in pairs({
    ERROR = '#fd4663', WARN = '#706bc7',
    INFO = '#9e70c2', DEBUG = '#616971',
    TRACE = '#75a0d7',
  }) do
    hi('Notify' .. level .. 'Body', { link = 'NormalFloat' })
    hi('Notify' .. level .. 'Border', { fg = color, bg = '#2b323b' })
    hi('Notify' .. level .. 'Icon', { link = 'Notify' .. level .. 'Border' })
    hi('Notify' .. level .. 'Title', { link = 'Notify' .. level .. 'Border' })
  end

  -- Popup & Autocompletion Menu (Pmenu)
  hi('Pmenu',                   { fg = '#f2f2f3',             bg = '#2b323b' })
  hi('PmenuSel',                { fg = '#1b1e22',                bg = '#75a0d7', bold = true })
  hi('PmenuSbar',               { bg = '#262d36' })
  hi('PmenuThumb',              { bg = '#616971' })

  -- Diagnostics
  hi('DiagnosticError',         { fg = '#fd4663' })
  hi('DiagnosticWarn',          { fg = '#706bc7' })
  hi('DiagnosticInfo',          { fg = '#9e70c2' })
  hi('DiagnosticHint',          { fg = '#c2a6d9' })
  hi('DiagnosticUnderlineError',{ sp = '#fd4663',                 undercurl = true })
  hi('DiagnosticUnderlineWarn', { sp = '#706bc7',             undercurl = true })
  hi('DiagnosticUnderlineInfo', { sp = '#9e70c2',              undercurl = true })
  hi('DiagnosticUnderlineHint', { sp = '#c2a6d9',    undercurl = true })

  -- Git Signs & Diffs
  hi('GitSignsAdd',             { fg = '#75a0d7' })
  hi('GitSignsChange',          { fg = '#9e70c2' })
  hi('GitSignsDelete',          { fg = '#fd4663' })
  hi('DiffAdd',                 { fg = '#75a0d7',                bg = '#2b323b' })
  hi('DiffChange',              { fg = '#9e70c2',               bg = '#2b323b' })
  hi('DiffDelete',              { fg = '#fd4663',                  bg = '#2b323b' })
  hi('DiffText',                { fg = '#706bc7',              bg = '#262d36', bold = true })

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
  hi('IblIndent',               { fg = '#2b323b' })
  hi('IblScope',                { fg = '#616971' })

  -- Bufferline: one opaque surface, quiet inactive names, an accented selection.
  hi('BufferLineFill',          { bg = '#1a1e23' })
  hi('BufferLineBackground',    { fg = '#616971', bg = '#1a1e23' })
  hi('BufferLineBufferVisible', { fg = '#f2f2f3', bg = '#1a1e23' })
  hi('BufferLineBufferSelected',{ fg = '#f2f2f3', bg = '#2b323b', bold = true })
  for _, group in ipairs({ 'BufferLineSeparator', 'BufferLineSeparatorVisible', 'BufferLineSeparatorSelected' }) do
    hi(group, { fg = '#1a1e23', bg = '#1a1e23' })
  end
  for _, part in ipairs({ 'Duplicate', 'CloseButton', 'Modified', 'Indicator' }) do
    hi('BufferLine' .. part, { fg = '#616971', bg = '#1a1e23' })
    hi('BufferLine' .. part .. 'Visible', { fg = '#616971', bg = '#1a1e23' })
    hi('BufferLine' .. part .. 'Selected', { fg = '#75a0d7', bg = '#2b323b' })
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f2f2f3',             bg = '#2b323b' })
  hi('TelescopeBorder',         { fg = '#616971',                bg = '#2b323b' })
  hi('TelescopeResultsNormal',  { link = 'TelescopeNormal' })
  hi('TelescopeResultsBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePreviewNormal',  { link = 'TelescopeNormal' })
  hi('TelescopePreviewBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',             bg = '#2b323b' })
  hi('TelescopePromptBorder',   { fg = '#616971',                bg = '#2b323b' })
  hi('TelescopePromptPrefix',   { fg = '#75a0d7',                bg = '#2b323b' })
  hi('TelescopePromptCounter',  { fg = '#afb2b6',     bg = '#2b323b' })
  hi('TelescopePromptTitle',    { fg = '#1b1e22',                bg = '#75a0d7', bold = true })
  hi('TelescopePreviewTitle',   { fg = '#030407',                bg = '#706bc7', bold = true })
  hi('TelescopeResultsTitle',   { fg = '#1a1c20',                bg = '#9e70c2', bold = true })
  hi('TelescopeSelection',      { fg = '#f2f2f3',             bg = '#262d36' })
  hi('TelescopeSelectionCaret', { fg = '#75a0d7',                bg = '#262d36' })
  hi('TelescopeMatching',       { fg = '#706bc7',              bold = true })

  -- Flash.nvim: underline the current match; reserve filled primary for jump keys.
  hi('FlashMatch',   { link = 'TelescopeSelection' })
  hi('FlashCurrent', { fg = '#706bc7', bg = '#262d36', bold = true, underline = true })
  hi('FlashLabel',   { fg = '#1b1e22', bg = '#75a0d7', bold = true, nocombine = true })

  -- mini.pick
  hi('MiniPickNormal',          { fg = '#f2f2f3',             bg = '#1a1e23' })
  hi('MiniPickBorder',          { fg = '#616971',                bg = '#1a1e23' })
  hi('MiniPickPrompt',          { fg = '#f2f2f3',             bg = '#1a1e23' })
  hi('MiniPickPromptPrefix',    { fg = '#75a0d7',                bg = '#1a1e23' })
  hi('MiniPickBorderText',      { fg = '#1b1e22',                bg = '#75a0d7' })
  hi('MiniPickMatchCurrent',    { fg = '#f2f2f3',             bg = '#262d36' })
  hi('MiniPickPromptCaret',     { fg = '#75a0d7',                bg = '#262d36' })
  hi('MiniPickMatchRanges',     { fg = '#75a0d7',                bold = true })

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
