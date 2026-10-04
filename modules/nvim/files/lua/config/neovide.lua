-- ==============================================================================
-- Neovide GUI Integration: Modern Noctalia Glassmorphic Aesthetics & Ergonomics
-- ==============================================================================

local M = {}

-- 1. Typography & Font (JetBrains Mono with Ligatures & generous line-height)
vim.o.guifont = "JetBrainsMono Nerd Font:h12.5:#e-subpixelantialias"
vim.opt.linespace = 4

-- 2. Modern Smooth Glide Cursor with Pixiedust Particle Effect
vim.g.neovide_cursor_animation_length = 0.08
vim.g.neovide_cursor_trail_size = 0.45
vim.g.neovide_cursor_antialiasing = true
vim.g.neovide_cursor_animate_in_insert_mode = true
vim.g.neovide_cursor_animate_command_line = true
vim.g.neovide_cursor_vfx_mode = "pixiedust"
vim.g.neovide_cursor_vfx_opacity = 200.0
vim.g.neovide_cursor_vfx_particle_speed = 10.0
vim.g.neovide_cursor_vfx_particle_density = 10.0
vim.g.neovide_cursor_vfx_particle_lifetime = 1.2

-- 3. Snappy Inertia Scrolling (Fluid & Responsive)
vim.g.neovide_scroll_animation_length = 0.16
vim.g.neovide_scroll_animation_far_lines = 1

-- 4. Canvas Padding (Spacious modern IDE layout matching Noctalia shell)
vim.g.neovide_padding_top = 14
vim.g.neovide_padding_bottom = 12
vim.g.neovide_padding_left = 18
vim.g.neovide_padding_right = 18

-- 5. Window Opacity & Floating Shadows (Noctalia Glassmorphism synced with Kitty)
vim.g.neovide_opacity = 0.86
vim.g.neovide_window_blurred = true
vim.g.neovide_floating_blur_amount_x = 4.0
vim.g.neovide_floating_blur_amount_y = 4.0
vim.g.neovide_floating_shadow = true
vim.g.neovide_floating_z_height = 12
vim.g.neovide_light_angle_degrees = 45
vim.g.neovide_light_radius = 6
vim.g.neovide_floating_corner_radius = 8.0

-- 6. Environment, Titlebar & UX
vim.g.neovide_title_background_color = "#282828"
vim.g.neovide_title_text_color = "#fbf1c7"
vim.g.neovide_hide_mouse_when_typing = true
vim.g.neovide_input_use_logo = true
vim.g.neovide_confirm_quit = true
vim.g.neovide_refresh_rate = 144
vim.g.neovide_remember_window_size = true

-- 7. Rounded Floating Windows & Borders (Modern Noctalia Look)
vim.diagnostic.config({
  float = {
    border = "rounded",
    focusable = false,
  },
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, { border = "rounded" }
)
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help, { border = "rounded" }
)

-- 8. Dynamic Scaling / Zooming (VSCode Ctrl+ / Ctrl-)
vim.g.neovide_scale_factor = 1.0
local change_scale_factor = function(delta)
  vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end

vim.keymap.set({ "n", "v" }, "<C-=>", function() change_scale_factor(1.1) end, { desc = "Zoom In (VSCode)" })
vim.keymap.set({ "n", "v" }, "<C-->", function() change_scale_factor(1 / 1.1) end, { desc = "Zoom Out (VSCode)" })
vim.keymap.set({ "n", "v" }, "<C-0>", function() vim.g.neovide_scale_factor = 1.0 end, { desc = "Reset Zoom (VSCode)" })

-- 9. Universal Modern GUI Keymaps (No Alt, Unified Ctrl+Shift for Move)
local map = vim.keymap.set

-- Save file (Ctrl+S) across all modes
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Lưu file (VSCode Ctrl+S)" })

-- Undo (Ctrl+Z) & Redo (Ctrl+Y / Ctrl+Shift+Z)
map("n", "<C-z>", "u", { desc = "Undo" })
map("i", "<C-z>", "<C-o>u", { desc = "Undo" })
map({ "n", "i" }, "<C-y>", "<C-r>", { desc = "Redo" })

-- Select All (Ctrl+A)
map({ "n", "i" }, "<C-a>", "<esc>ggVG", { desc = "Chọn tất cả (Select All)" })

-- Copy to Clipboard (Ctrl+C in Visual)
map("v", "<C-c>", '"+y', { desc = "Copy to system clipboard" })

-- Paste from Clipboard (Ctrl+V in Insert)
map("i", "<C-v>", "<C-r>+", { desc = "Paste from system clipboard" })
map("c", "<C-v>", "<C-r>+", { desc = "Paste from system clipboard" })

-- Toggle Sidebar Explorer (Ctrl+B like VSCode/WebStorm)
map({ "n", "i" }, "<C-b>", "<cmd>NvimTreeToggle<cr>", { desc = "Bật/Tắt Sidebar Explorer (VSCode Ctrl+B)" })

-- Quick Open File (Ctrl+P like VSCode)
map("n", "<C-p>", "<cmd>Telescope find_files<cr>", { desc = "Tìm file nhanh (VSCode Ctrl+P)" })

-- Global Grep / Search (Ctrl+Shift+F like VSCode)
map("n", "<C-S-f>", "<cmd>Telescope live_grep<cr>", { desc = "Tìm kiếm toàn dự án (VSCode Ctrl+Shift+F)" })

-- Command Palette (Ctrl+Shift+P like VSCode)
map("n", "<C-S-p>", "<cmd>Telescope keymaps<cr>", { desc = "Command Palette (VSCode Ctrl+Shift+P)" })

-- Line Moving: Support both Ctrl+Shift+Up/Down (Universal Move) and Alt+Up/Down
map("n", "<C-S-Down>", ":m .+1<CR>==", { desc = "Di chuyển dòng xuống (Ctrl+Shift+Down)", silent = true })
map("n", "<C-S-Up>", ":m .-2<CR>==", { desc = "Di chuyển dòng lên (Ctrl+Shift+Up)", silent = true })
map("v", "<C-S-Down>", ":m '>+1<CR>gv=gv", { desc = "Di chuyển khối xuống (Ctrl+Shift+Down)", silent = true })
map("v", "<C-S-Up>", ":m '<-2<CR>gv=gv", { desc = "Di chuyển khối lên (Ctrl+Shift+Up)", silent = true })

map("n", "<M-Down>", ":m .+1<CR>==", { desc = "Di chuyển dòng xuống (Alt+Down)", silent = true })
map("n", "<M-Up>", ":m .-2<CR>==", { desc = "Di chuyển dòng lên (Alt+Up)", silent = true })
map("v", "<M-Down>", ":m '>+1<CR>gv=gv", { desc = "Di chuyển khối xuống (Alt+Down)", silent = true })
map("v", "<M-Up>", ":m '<-2<CR>gv=gv", { desc = "Di chuyển khối lên (Alt+Up)", silent = true })

-- Line Duplication (Shift+Alt+Down / Shift+Alt+Up like VSCode)
map("n", "<M-S-Down>", "yyp", { desc = "Nhân bản dòng xuống dưới", silent = true })
map("n", "<M-S-Up>", "yyP", { desc = "Nhân bản dòng lên trên", silent = true })

-- Auto-open Explorer tree when opening a directory in Neovide
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    local directory = vim.fn.isdirectory(data.file) == 1
    if directory then
      vim.cmd.cd(data.file)
      require("nvim-tree.api").tree.open()
    end
  end,
})

return M
