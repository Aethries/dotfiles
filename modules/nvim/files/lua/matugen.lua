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

  -- Window & Split chrome
  hi('WinSeparator',            { fg = '#474240', bg = 'NONE' })
  hi('VertSplit',               { fg = '#474240', bg = 'NONE' })
  hi('CursorLine',              { bg = '#3c3836' })
  hi('CursorLineNr',            { fg = '#fabd2f',             bold = true })
  hi('LineNr',                  { fg = '#76706c' })
  hi('SignColumn',              { bg = 'NONE' })

  -- Floating Windows
  hi('NormalFloat',             { fg = '#fbf1c7',             bg = '#3c3836' })
  hi('FloatBorder',             { fg = '#76706c',                bg = '#3c3836' })
  hi('FloatTitle',              { fg = '#282828',                bg = '#b8bb26', bold = true })

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

  -- Indent Blankline
  hi('IblIndent',               { fg = '#3c3836' })
  hi('IblScope',                { fg = '#76706c' })

  -- Bufferline
  hi('BufferLineFill',          { bg = '#282828' })
  hi('BufferLineBackground',    { fg = '#76706c',                bg = '#3c3836' })
  hi('BufferLineBufferSelected',{ fg = '#fbf1c7',             bg = '#282828', bold = true })
  hi('BufferLineSeparator',     { fg = '#282828',                bg = '#3c3836' })
  hi('BufferLineSeparatorSelected', { fg = '#282828',            bg = '#282828' })
  hi('BufferLineIndicatorSelected', { fg = '#b8bb26',            bg = '#282828' })

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#fbf1c7',             bg = '#282828' })
  hi('TelescopeBorder',         { fg = '#76706c',                bg = '#282828' })
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

  -- mini.pick
  hi('MiniPickNormal',          { fg = '#fbf1c7',             bg = '#282828' })
  hi('MiniPickBorder',          { fg = '#76706c',                bg = '#282828' })
  hi('MiniPickPrompt',          { fg = '#fbf1c7',             bg = '#282828' })
  hi('MiniPickPromptPrefix',    { fg = '#b8bb26',                bg = '#282828' })
  hi('MiniPickBorderText',      { fg = '#282828',                bg = '#b8bb26' })
  hi('MiniPickMatchCurrent',    { fg = '#fbf1c7',             bg = '#474240' })
  hi('MiniPickPromptCaret',     { fg = '#b8bb26',                bg = '#474240' })
  hi('MiniPickMatchRanges',     { fg = '#b8bb26',                bold = true })
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
