 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#091134',
    base01 = '#101d56',
    base02 = '#0e1a4e',
    base03 = '#5e626e',
    base04 = '#afb0b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#c552e0',
    base0A = '#8152e0',
    base0B = '#677ee4',
    base0C = '#db93ec',
    base0D = '#93a3ec',
    base0E = '#b093ec',
    base0F = '#d0bef4',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#091134' })
  hi('TelescopeBorder',         { fg = '#5e626e',             bg = '#091134' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#091134' })
  hi('TelescopePromptBorder',   { fg = '#5e626e',             bg = '#091134' })
  hi('TelescopePromptPrefix',   { fg = '#677ee4',             bg = '#091134' })
  hi('TelescopePromptCounter',  { fg = '#afb0b6',  bg = '#091134' })
  hi('TelescopePromptTitle',    { fg = '#091134',             bg = '#677ee4' })
  hi('TelescopePreviewTitle',   { fg = '#091134',             bg = '#8152e0' })
  hi('TelescopeResultsTitle',   { fg = '#091134',             bg = '#c552e0' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#0e1a4e' })
  hi('TelescopeSelectionCaret', { fg = '#677ee4',             bg = '#0e1a4e' })
  hi('TelescopeMatching',       { fg = '#677ee4',             bold = true })
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
