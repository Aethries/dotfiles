-- Style policy lives in this repository; Noctalia replaces only color tokens.
-- Edit this template, not the generated lua/matugen.lua.
local M = {}

function M.setup()
  local ok, base16 = pcall(require, 'base16-colorscheme')
  if not ok then
    return
  end

  base16.setup({
    base00 = '#21252b',
    base01 = '#282c34',
    base02 = '#313640',
    base03 = '#696e78',
    base04 = '#78c4ce',
    base05 = '#c9ccd3',
    base06 = '#c9ccd3',
    base07 = '#c9ccd3',
    base08 = '#e27881',
    base09 = '#98c379',
    base0A = '#eac786',
    base0B = '#62bac6',
    base0C = '#b9e996',
    base0D = '#96dfe9',
    base0E = '#eccd92',
    base0F = '#f4e1be',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  local editor_background = vim.g.neovide and '#21252b' or 'NONE'
  if vim.g.neovide then
    -- GUI cells need an explicit theme background, including empty/gutter areas.
    hi('Normal', { fg = '#c9ccd3', bg = editor_background })
    hi('NormalNC', { link = 'Normal' })
    hi('EndOfBuffer', { fg = '#696e78', bg = editor_background })
    vim.g.neovide_title_background_color = '#21252b'
    vim.g.neovide_title_text_color = '#c9ccd3'
  end

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '#313640', bg = 'NONE' })
  hi('VertSplit',               { fg = '#313640', bg = 'NONE' })
  hi('CursorLine',              { bg = '#282c34' })
  hi('CursorLineNr',            { fg = '#eac786',             bold = true })
  hi('LineNr',                  { fg = '#696e78' })
  hi('SignColumn',              { bg = editor_background })

  -- NvimTree: retain the GUI theme surface; terminals inherit their background.
  hi('NvimTreeNormal',          { fg = '#c9ccd3',            bg = editor_background })
  hi('NvimTreeNormalNC',        { fg = '#c9ccd3',            bg = editor_background })
  hi('NvimTreeEndOfBuffer',     { fg = '#696e78',               bg = editor_background })
  hi('NvimTreeWinSeparator',    { fg = '#393e47',       bg = 'NONE' })
  hi('NvimTreeCursorLine',      { bg = '#282c34' })
  hi('NvimTreeRootFolder',      { fg = '#62bac6',               bold = true })
  hi('NvimTreeFolderName',      { fg = '#78c4ce' })
  hi('NvimTreeOpenedFolderName',{ fg = '#c9ccd3',            bold = true })
  hi('NvimTreeFolderIcon',      { fg = '#98c379' })
  hi('NvimTreeOpenedFolderIcon',{ fg = '#eac786' })
  hi('NvimTreeIndentMarker',    { fg = '#696e78' })
  hi('NvimTreeGitDeletedIcon',  { fg = '#e27881' })
  hi('NvimTreeGitDirtyIcon',    { fg = '#eac786' })
  hi('NvimTreeGitIgnoredIcon',  { fg = '#696e78' })
  hi('NvimTreeGitMergeIcon',    { fg = '#98c379' })
  hi('NvimTreeGitNewIcon',      { fg = '#62bac6' })
  hi('NvimTreeGitRenamedIcon',  { fg = '#b9e996' })
  hi('NvimTreeGitStagedIcon',   { fg = '#62bac6' })
  hi('NvimTreeGitFileDeletedHL',{ fg = '#e27881' })
  hi('NvimTreeGitFileDirtyHL',  { fg = '#eac786' })
  hi('NvimTreeGitFileIgnoredHL',{ fg = '#696e78' })
  hi('NvimTreeGitFileMergeHL',  { fg = '#98c379' })
  hi('NvimTreeGitFileNewHL',    { fg = '#62bac6' })
  hi('NvimTreeGitFileRenamedHL',{ fg = '#b9e996' })
  hi('NvimTreeGitFileStagedHL', { fg = '#62bac6' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '#c9ccd3',             bg = '#282c34' })
  hi('FloatBorder',             { fg = '#696e78',                bg = '#282c34' })
  hi('FloatTitle',              { fg = '#21252b',                bg = '#62bac6', bold = true })

  -- Dialogs must not inherit the transparent Normal background.
  for _, group in ipairs({ 'NoiceCmdlinePopup', 'NoiceConfirm', 'NoiceMini', 'WhichKeyNormal' }) do
    hi(group, { link = 'NormalFloat' })
  end
  for _, group in ipairs({ 'NoiceCmdlinePopupBorder', 'NoiceCmdlinePopupBorderSearch', 'NoiceConfirmBorder', 'WhichKeyBorder' }) do
    hi(group, { link = 'FloatBorder' })
  end
  for level, color in pairs({
    ERROR = '#e27881', WARN = '#eac786',
    INFO = '#98c379', DEBUG = '#696e78',
    TRACE = '#62bac6',
  }) do
    hi('Notify' .. level .. 'Body', { link = 'NormalFloat' })
    hi('Notify' .. level .. 'Border', { fg = color, bg = '#282c34' })
    hi('Notify' .. level .. 'Icon', { link = 'Notify' .. level .. 'Border' })
    hi('Notify' .. level .. 'Title', { link = 'Notify' .. level .. 'Border' })
  end

  -- Popup & Autocompletion Menu (Pmenu)
  hi('Pmenu',                   { fg = '#c9ccd3',             bg = '#282c34' })
  hi('PmenuSel',                { fg = '#21252b',                bg = '#62bac6', bold = true })
  hi('PmenuSbar',               { bg = '#313640' })
  hi('PmenuThumb',              { bg = '#696e78' })

  -- Diagnostics
  hi('DiagnosticError',         { fg = '#e27881' })
  hi('DiagnosticWarn',          { fg = '#eac786' })
  hi('DiagnosticInfo',          { fg = '#98c379' })
  hi('DiagnosticHint',          { fg = '#b9e996' })
  hi('DiagnosticUnderlineError',{ sp = '#e27881',                 undercurl = true })
  hi('DiagnosticUnderlineWarn', { sp = '#eac786',             undercurl = true })
  hi('DiagnosticUnderlineInfo', { sp = '#98c379',              undercurl = true })
  hi('DiagnosticUnderlineHint', { sp = '#b9e996',    undercurl = true })

  -- Git Signs & Diffs
  hi('GitSignsAdd',             { fg = '#62bac6' })
  hi('GitSignsChange',          { fg = '#98c379' })
  hi('GitSignsDelete',          { fg = '#e27881' })
  hi('DiffAdd',                 { fg = '#62bac6',                bg = '#282c34' })
  hi('DiffChange',              { fg = '#98c379',               bg = '#282c34' })
  hi('DiffDelete',              { fg = '#e27881',                  bg = '#282c34' })
  hi('DiffText',                { fg = '#eac786',              bg = '#313640', bold = true })

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
  hi('IblIndent',               { fg = '#282c34' })
  hi('IblScope',                { fg = '#696e78' })

  -- Bufferline: one opaque surface, quiet inactive names, an accented selection.
  hi('BufferLineFill',          { bg = '#21252b' })
  hi('BufferLineBackground',    { fg = '#696e78', bg = '#21252b' })
  hi('BufferLineBufferVisible', { fg = '#c9ccd3', bg = '#21252b' })
  hi('BufferLineBufferSelected',{ fg = '#c9ccd3', bg = '#282c34', bold = true })
  for _, group in ipairs({ 'BufferLineSeparator', 'BufferLineSeparatorVisible', 'BufferLineSeparatorSelected' }) do
    hi(group, { fg = '#21252b', bg = '#21252b' })
  end
  for _, part in ipairs({ 'Duplicate', 'CloseButton', 'Modified', 'Indicator' }) do
    hi('BufferLine' .. part, { fg = '#696e78', bg = '#21252b' })
    hi('BufferLine' .. part .. 'Visible', { fg = '#696e78', bg = '#21252b' })
    hi('BufferLine' .. part .. 'Selected', { fg = '#62bac6', bg = '#282c34' })
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#c9ccd3',             bg = '#282c34' })
  hi('TelescopeBorder',         { fg = '#696e78',                bg = '#282c34' })
  hi('TelescopeResultsNormal',  { link = 'TelescopeNormal' })
  hi('TelescopeResultsBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePreviewNormal',  { link = 'TelescopeNormal' })
  hi('TelescopePreviewBorder',  { link = 'TelescopeBorder' })
  hi('TelescopePromptNormal',   { fg = '#c9ccd3',             bg = '#282c34' })
  hi('TelescopePromptBorder',   { fg = '#696e78',                bg = '#282c34' })
  hi('TelescopePromptPrefix',   { fg = '#62bac6',                bg = '#282c34' })
  hi('TelescopePromptCounter',  { fg = '#78c4ce',     bg = '#282c34' })
  hi('TelescopePromptTitle',    { fg = '#21252b',                bg = '#62bac6', bold = true })
  hi('TelescopePreviewTitle',   { fg = '#21252b',                bg = '#eac786', bold = true })
  hi('TelescopeResultsTitle',   { fg = '#21252b',                bg = '#98c379', bold = true })
  hi('TelescopeSelection',      { fg = '#c9ccd3',             bg = '#313640' })
  hi('TelescopeSelectionCaret', { fg = '#62bac6',                bg = '#313640' })
  hi('TelescopeMatching',       { fg = '#eac786',              bold = true })

  -- Flash.nvim: underline the current match; reserve filled primary for jump keys.
  hi('FlashMatch',   { link = 'TelescopeSelection' })
  hi('FlashCurrent', { fg = '#eac786', bg = '#313640', bold = true, underline = true })
  hi('FlashLabel',   { fg = '#21252b', bg = '#62bac6', bold = true, nocombine = true })

  -- mini.pick
  hi('MiniPickNormal',          { fg = '#c9ccd3',             bg = '#21252b' })
  hi('MiniPickBorder',          { fg = '#696e78',                bg = '#21252b' })
  hi('MiniPickPrompt',          { fg = '#c9ccd3',             bg = '#21252b' })
  hi('MiniPickPromptPrefix',    { fg = '#62bac6',                bg = '#21252b' })
  hi('MiniPickBorderText',      { fg = '#21252b',                bg = '#62bac6' })
  hi('MiniPickMatchCurrent',    { fg = '#c9ccd3',             bg = '#313640' })
  hi('MiniPickPromptCaret',     { fg = '#62bac6',                bg = '#313640' })
  hi('MiniPickMatchRanges',     { fg = '#62bac6',                bold = true })

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
