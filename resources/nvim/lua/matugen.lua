 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1d1c21',
    base01 = '#302f37',
    base02 = '#2b2a32',
    base03 = '#686673',
    base04 = '#b0afb6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#cc66bc',
    base0A = '#b15cd6',
    base0B = '#7a67e4',
    base0C = '#e996dc',
    base0D = '#a093ec',
    base0E = '#d096e9',
    base0F = '#e3bef4',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#1d1c21' })
  hi('TelescopeBorder',         { fg = '#686673',             bg = '#1d1c21' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#1d1c21' })
  hi('TelescopePromptBorder',   { fg = '#686673',             bg = '#1d1c21' })
  hi('TelescopePromptPrefix',   { fg = '#7a67e4',             bg = '#1d1c21' })
  hi('TelescopePromptCounter',  { fg = '#b0afb6',  bg = '#1d1c21' })
  hi('TelescopePromptTitle',    { fg = '#1d1c21',             bg = '#7a67e4' })
  hi('TelescopePreviewTitle',   { fg = '#1d1c21',             bg = '#b15cd6' })
  hi('TelescopeResultsTitle',   { fg = '#1d1c21',             bg = '#cc66bc' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#2b2a32' })
  hi('TelescopeSelectionCaret', { fg = '#7a67e4',             bg = '#2b2a32' })
  hi('TelescopeMatching',       { fg = '#7a67e4',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#f2f2f3',          bg = '#1d1c21' })
  hi('MiniPickBorder',         { fg = '#686673',             bg = '#1d1c21' })
  hi('MiniPickPrompt',   { fg = '#f2f2f3',          bg = '#1d1c21' })
  hi('MiniPickPromptPrefix',   { fg = '#7a67e4',             bg = '#1d1c21' })
  hi('MiniPickBorderText',    { fg = '#1d1c21',             bg = '#7a67e4' })
  hi('MiniPickMatchCurrent',      { fg = '#f2f2f3',          bg = '#2b2a32' })
  hi('MiniPickPromptCaret', { fg = '#7a67e4',             bg = '#2b2a32' })
  hi('MiniPickMatchRanges',       { fg = '#7a67e4',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
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
