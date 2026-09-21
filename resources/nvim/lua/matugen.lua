 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#031d3a',
    base01 = '#0f3057',
    base02 = '#0b2b50',
    base03 = '#616870',
    base04 = '#afb2b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#be76fc',
    base0A = '#7b76fc',
    base0B = '#76b4fc',
    base0C = '#c482fc',
    base0D = '#82bbfc',
    base0E = '#8782fc',
    base0F = '#b7b4fd',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#031d3a' })
  hi('TelescopeBorder',         { fg = '#616870',             bg = '#031d3a' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#031d3a' })
  hi('TelescopePromptBorder',   { fg = '#616870',             bg = '#031d3a' })
  hi('TelescopePromptPrefix',   { fg = '#76b4fc',             bg = '#031d3a' })
  hi('TelescopePromptCounter',  { fg = '#afb2b6',  bg = '#031d3a' })
  hi('TelescopePromptTitle',    { fg = '#031d3a',             bg = '#76b4fc' })
  hi('TelescopePreviewTitle',   { fg = '#031d3a',             bg = '#7b76fc' })
  hi('TelescopeResultsTitle',   { fg = '#031d3a',             bg = '#be76fc' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#0b2b50' })
  hi('TelescopeSelectionCaret', { fg = '#76b4fc',             bg = '#0b2b50' })
  hi('TelescopeMatching',       { fg = '#76b4fc',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#f2f2f3',          bg = '#031d3a' })
  hi('MiniPickBorder',         { fg = '#616870',             bg = '#031d3a' })
  hi('MiniPickPrompt',   { fg = '#f2f2f3',          bg = '#031d3a' })
  hi('MiniPickPromptPrefix',   { fg = '#76b4fc',             bg = '#031d3a' })
  hi('MiniPickBorderText',    { fg = '#031d3a',             bg = '#76b4fc' })
  hi('MiniPickMatchCurrent',      { fg = '#f2f2f3',          bg = '#0b2b50' })
  hi('MiniPickPromptCaret', { fg = '#76b4fc',             bg = '#0b2b50' })
  hi('MiniPickMatchRanges',       { fg = '#76b4fc',             bold = true })
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
