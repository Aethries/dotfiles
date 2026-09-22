 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#152128',
    base01 = '#233843',
    base02 = '#1f323c',
    base03 = '#616b70',
    base04 = '#afb4b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#8a66cc',
    base0A = '#5c6ed6',
    base0B = '#67b8e4',
    base0C = '#b396e9',
    base0D = '#93ccec',
    base0E = '#96a2e9',
    base0F = '#bec6f4',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#152128' })
  hi('TelescopeBorder',         { fg = '#616b70',             bg = '#152128' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#152128' })
  hi('TelescopePromptBorder',   { fg = '#616b70',             bg = '#152128' })
  hi('TelescopePromptPrefix',   { fg = '#67b8e4',             bg = '#152128' })
  hi('TelescopePromptCounter',  { fg = '#afb4b6',  bg = '#152128' })
  hi('TelescopePromptTitle',    { fg = '#152128',             bg = '#67b8e4' })
  hi('TelescopePreviewTitle',   { fg = '#152128',             bg = '#5c6ed6' })
  hi('TelescopeResultsTitle',   { fg = '#152128',             bg = '#8a66cc' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#1f323c' })
  hi('TelescopeSelectionCaret', { fg = '#67b8e4',             bg = '#1f323c' })
  hi('TelescopeMatching',       { fg = '#67b8e4',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#f2f2f3',          bg = '#152128' })
  hi('MiniPickBorder',         { fg = '#616b70',             bg = '#152128' })
  hi('MiniPickPrompt',   { fg = '#f2f2f3',          bg = '#152128' })
  hi('MiniPickPromptPrefix',   { fg = '#67b8e4',             bg = '#152128' })
  hi('MiniPickBorderText',    { fg = '#152128',             bg = '#67b8e4' })
  hi('MiniPickMatchCurrent',      { fg = '#f2f2f3',          bg = '#1f323c' })
  hi('MiniPickPromptCaret', { fg = '#67b8e4',             bg = '#1f323c' })
  hi('MiniPickMatchRanges',       { fg = '#67b8e4',             bold = true })
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
