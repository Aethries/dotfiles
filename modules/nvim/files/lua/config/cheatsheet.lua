-- ==============================================================================
-- Bilingual Interactive Cheatsheet (English & Tiếng Việt) for Telescope
-- Searchable by keybinds, categories, or functional descriptions
-- ==============================================================================

local M = {}

M.items = {
  -- General & Editing
  { key = "<leader>w", cat = "General", en = "Save file", vi = "Lưu file", action = "w" },
  { key = "<leader>as / <leader>ta", cat = "General", en = "Toggle auto-save buffers on idle/blur", vi = "Bật/Tắt tự động lưu buffer khi dừng gõ (AutoSave)", action = "ASToggle" },
  { key = "<leader>q", cat = "General", en = "Close window", vi = "Đóng cửa sổ", action = "q" },
  { key = "<Esc>", cat = "General", en = "Clear search highlight", vi = "Xóa highlight tìm kiếm", action = "nohlsearch" },
  { key = "jk", cat = "General", en = "Escape insert mode", vi = "Thoát Insert mode nhanh" },
  { key = "<leader>bd", cat = "Buffer", en = "Close current buffer", vi = "Đóng buffer hiện tại", action = "bdelete" },
  { key = "<S-h>", cat = "Buffer", en = "Previous buffer", vi = "Buffer trước đó", action = "bprevious" },
  { key = "<S-l>", cat = "Buffer", en = "Next buffer", vi = "Buffer tiếp theo", action = "bnext" },
  { key = "< / >", cat = "Visual", en = "Indent left/right (keep selection)", vi = "Thụt lề trái/phải (giữ vùng chọn)" },
  { key = "J / K", cat = "Visual", en = "Move selected block down/up", vi = "Di chuyển khối code xuống/lên" },
  { key = "p", cat = "Visual", en = "Paste without overwriting clipboard register", vi = "Dán không ghi đè clipboard register" },
  { key = "<leader>tt", cat = "UI", en = "Toggle transparency (glassmorphism/blur)", vi = "Bật/Tắt nền trong suốt (kính mờ Kitty)", action = "TransparentToggle" },

  -- Window Navigation & Resizing (Zellij + Neovim)
  { key = "<C-h>", cat = "Window", en = "Move split left or Zellij pane left", vi = "Chuyển split hoặc pane Zellij sang trái", action = "ZellijNavigateLeftTab" },
  { key = "<C-j>", cat = "Window", en = "Move split down or Zellij pane down", vi = "Chuyển split hoặc pane Zellij xuống dưới", action = "ZellijNavigateDown" },
  { key = "<C-k>", cat = "Window", en = "Move split up or Zellij pane up", vi = "Chuyển split hoặc pane Zellij lên trên", action = "ZellijNavigateUp" },
  { key = "<C-l>", cat = "Window", en = "Move split right or Zellij pane right", vi = "Chuyển split hoặc pane Zellij sang phải", action = "ZellijNavigateRightTab" },
  { key = "Ctrl+Alt+h / l", cat = "Window", en = "Direct resize pane width (-/+)", vi = "Chỉnh nhanh chiều rộng pane (-/+)" },
  { key = "Ctrl+Alt+j / k", cat = "Window", en = "Direct resize pane height (-/+)", vi = "Chỉnh nhanh chiều cao pane (-/+)" },
  { key = "<leader>wr", cat = "Window", en = "Interactive resize submode (tap h/j/k/l)", vi = "Chế độ chỉnh kích thước tương tác (gõ h/j/k/l liên tục)" },
  { key = "<leader>wm", cat = "Window", en = "Toggle maximize / restore current pane", vi = "Phóng to / khôi phục kích thước pane (Maximize)" },
  { key = "<leader>w=", cat = "Window", en = "Equalize all window/pane sizes", vi = "Cân bằng kích thước tất cả cửa sổ", action = "wincmd =" },
  { key = "<leader>wh / wl", cat = "Window", en = "Decrease / increase pane width (-/+4)", vi = "Giảm / tăng chiều rộng pane (-/+4)" },
  { key = "<leader>wj / wk", cat = "Window", en = "Decrease / increase pane height (-/+4)", vi = "Giảm / tăng chiều cao pane (-/+4)" },
  { key = "<leader>wv", cat = "Window", en = "Split window vertically", vi = "Tách cửa sổ dọc (vsplit)", action = "vsplit" },
  { key = "<leader>ws", cat = "Window", en = "Split window horizontally", vi = "Tách cửa sổ ngang (split)", action = "split" },
  { key = "<leader>wx", cat = "Window", en = "Close current split window", vi = "Đóng cửa sổ split hiện tại", action = "close" },
  { key = "<leader>to / <leader>tx", cat = "Tab", en = "Open / close tabpage", vi = "Mở / đóng tab mới", action = "tabnew" },
  { key = "<leader>tn / <leader>tp", cat = "Tab", en = "Next / previous tabpage", vi = "Tab tiếp theo / tab trước đó", action = "tabnext" },

  -- Motions & Navigation
  { key = "w", cat = "Motion", en = "Subword forward (camelCase/snake_case/kebab-case)", vi = "Nhảy từ con tiến tới (hỗ trợ camel/snake/kebab)" },
  { key = "e", cat = "Motion", en = "Subword end (camelCase/snake_case/kebab-case)", vi = "Nhảy đến cuối từ con" },
  { key = "b", cat = "Motion", en = "Subword backward (camelCase/snake_case/kebab-case)", vi = "Nhảy từ con lùi lại" },
  { key = "ge", cat = "Motion", en = "Subword backward end", vi = "Nhảy lùi đến cuối từ con" },
  { key = "s", cat = "Motion", en = "Flash 2D jump anywhere on screen", vi = "Nhảy 2D nhanh tới ký tự bất kỳ trên màn hình (Flash)" },
  { key = "S", cat = "Motion", en = "Flash Treesitter syntax node select", vi = "Nhảy và chọn khối cú pháp Treesitter (Flash)" },
  { key = "<leader>e", cat = "Explorer", en = "Toggle file explorer tree", vi = "Bật/Tắt cây thư mục (NvimTree)", action = "NvimTreeToggle" },

  -- Harpoon (Fast Project File Switching)
  { key = "<leader>a", cat = "Harpoon", en = "Add / pin current file to Harpoon", vi = "Ghim file hiện tại vào Harpoon" },
  { key = "<C-e> / <leader>H", cat = "Harpoon", en = "Toggle Harpoon quick menu", vi = "Mở menu các file đã ghim trong Harpoon" },
  { key = "<leader>1..4", cat = "Harpoon", en = "Jump instantly to pinned file 1, 2, 3, or 4", vi = "Nhảy nhanh tới file đã ghim 1, 2, 3 hoặc 4" },
  { key = "<leader>hp / <leader>hn", cat = "Harpoon", en = "Previous / next Harpoon file", vi = "Chuyển tới file ghim trước đó / tiếp theo" },

  -- Telescope Fuzzy Search
  { key = "<leader>ff", cat = "Telescope", en = "Find files by filename", vi = "Tìm kiếm file theo tên", action = "Telescope find_files" },
  { key = "<leader>fg", cat = "Telescope", en = "Live grep text in project", vi = "Tìm kiếm nội dung (Grep) trong project", action = "Telescope live_grep" },
  { key = "<leader>fb", cat = "Telescope", en = "List and switch open buffers", vi = "Xem danh sách và chuyển buffer đang mở", action = "Telescope buffers" },
  { key = "<leader>fr", cat = "Telescope", en = "Search recently opened files", vi = "Tìm danh sách file đã mở gần đây", action = "Telescope oldfiles" },
  { key = "<leader>fs", cat = "Telescope", en = "Search Git status modified files", vi = "Tìm file thay đổi trong Git Status", action = "Telescope git_status" },
  { key = "<leader>fh", cat = "Telescope", en = "Search help documentation tags", vi = "Tra cứu tài liệu trợ giúp Neovim", action = "Telescope help_tags" },
  { key = "<leader>?", cat = "Telescope", en = "Interactive cheatsheet (EN / VI)", vi = "Bảng tra cứu phím tắt Anh - Việt tương tác" },

  -- DX & Refactoring (TreeSJ, Mini.ai, Neogen, Yazi, Aerial, AI, ColorPicker)
  { key = "<leader>j", cat = "DX", en = "Split / Join code block toggle (TreeSJ)", vi = "Chuyển đổi khối code 1 dòng / nhiều dòng (TreeSJ)" },
  { key = "<leader>ng", cat = "DX", en = "Auto-generate typed JSDoc / TSDoc (Neogen)", vi = "Tự động tạo chú thích hàm JSDoc / TSDoc (Neogen)" },
  { key = "<leader>y / <leader>Y", cat = "DX", en = "Open Yazi file manager popup (Current dir / Root)", vi = "Mở trình quản lý file Yazi nổi (Thư mục / Gốc)" },
  { key = "<leader>O / <leader>ao", cat = "DX", en = "Toggle code symbol outline sidebar (Aerial)", vi = "Bật/Tắt cây cấu trúc hàm/biến (Aerial Outline)", action = "AerialToggle! left" },
  { key = "<leader>aO", cat = "DX", en = "Floating code symbol outline (Aerial)", vi = "Xem cây cấu trúc hàm/biến dạng popup (Aerial)", action = "AerialNavToggle" },
  { key = "<leader>cp", cat = "DX", en = "Interactive color picker popup (CCC)", vi = "Bảng chọn mã màu trực quan tương tác (Color Picker)", action = "CccPick" },
  { key = "<leader>re", cat = "Refactor", en = "Interactive refactoring menu (Refactoring.nvim)", vi = "Menu tái cấu trúc mã tương tác (Refactoring)" },
  { key = "<leader>rf", cat = "Refactor", en = "Extract visual selection to new function", vi = "Trích xuất vùng chọn thành hàm riêng" },
  { key = "<leader>rv", cat = "Refactor", en = "Extract visual selection to variable", vi = "Trích xuất vùng chọn thành biến" },
  { key = "<leader>ri", cat = "Refactor", en = "Inline variable under cursor", vi = "Gộp biến vào biểu thức trực tiếp" },
  { key = "vaf / vif", cat = "TextObject", en = "Select around / inside function (Mini.ai)", vi = "Chọn bao quanh / bên trong hàm (Mini.ai)" },
  { key = "vac / vic", cat = "TextObject", en = "Select around / inside class (Mini.ai)", vi = "Chọn bao quanh / bên trong class (Mini.ai)" },
  { key = "vaa / via", cat = "TextObject", en = "Select around / inside argument (Mini.ai)", vi = "Chọn bao quanh / bên trong tham số hàm (Mini.ai)" },
  { key = "<C-f>", cat = "AI", en = "Accept Supermaven inline AI code completion", vi = "Chấp nhận gợi ý code AI Supermaven" },
  { key = "<C-j>", cat = "AI", en = "Accept Supermaven word suggestion", vi = "Chấp nhận 1 từ gợi ý AI Supermaven" },

  -- LSP & Code Intelligence
  { key = "gd", cat = "LSP", en = "Go to symbol definition", vi = "Đi đến nơi định nghĩa hàm/biến", action = "lua vim.lsp.buf.definition()" },
  { key = "gr", cat = "LSP", en = "Find all references", vi = "Tìm tất cả tham chiếu của symbol", action = "lua vim.lsp.buf.references()" },
  { key = "K", cat = "LSP", en = "Hover documentation / type info", vi = "Xem tài liệu kiểu dữ liệu hàm/biến", action = "lua vim.lsp.buf.hover()" },
  { key = "<leader>ca", cat = "LSP", en = "Code actions with live diff preview (ActionsPreview)", vi = "Gợi ý sửa lỗi nhanh với xem trước (Actions Preview)" },
  { key = "<leader>rn / <leader>cr", cat = "LSP", en = "Live incremental rename (real-time preview)", vi = "Đổi tên symbol trực tiếp với xem trước", action = "IncRename" },
  { key = "<leader>cd", cat = "LSP", en = "Show line diagnostic float", vi = "Xem chi tiết lỗi dòng hiện tại", action = "lua vim.diagnostic.open_float()" },
  { key = "[d / ]d", cat = "LSP", en = "Jump to previous / next diagnostic", vi = "Nhảy tới lỗi cảnh báo trước / tiếp theo" },
  { key = "<leader>ci", cat = "LSP", en = "LSP incoming calls hierarchy", vi = "Xem danh sách các hàm gọi tới đây (Incoming Calls)", action = "lua vim.lsp.buf.incoming_calls()" },
  { key = "<leader>co", cat = "LSP", en = "LSP outgoing calls hierarchy", vi = "Xem danh sách các hàm được gọi từ đây (Outgoing Calls)", action = "lua vim.lsp.buf.outgoing_calls()" },
  { key = "<leader>cf", cat = "LSP", en = "Format code buffer (Conform)", vi = "Định dạng mã nguồn (Conform)", action = "lua require('conform').format({ lsp_fallback = true })" },
  { key = "<leader>th", cat = "LSP", en = "Toggle inline type & parameter hints (Inlay Hints)", vi = "Bật/Tắt gợi ý kiểu dữ liệu và tham số (Inlay Hints)" },
  { key = "<leader>tc", cat = "Code", en = "Toggle sticky context header (Treesitter)", vi = "Bật/Tắt thanh ngữ cảnh hàm/class dính ở đầu", action = "TSContextToggle" },
  { key = "<leader>tm", cat = "Code", en = "Toggle rich markdown rendering (Render Markdown)", vi = "Bật/Tắt hiển thị Markdown đẹp (Render Markdown)", action = "RenderMarkdown toggle" },
  { key = "<leader>sr", cat = "Search", en = "Project-wide live search and replace (GrugFar)", vi = "Tìm và thay thế toàn dự án trực tiếp (GrugFar)", action = "GrugFar" },
  { key = "<leader>sw", cat = "Search", en = "Search & replace current word across project (GrugFar)", vi = "Tìm và thay thế từ tại con trỏ trên toàn dự án (GrugFar)" },
  { key = "[k", cat = "Code", en = "Jump up to sticky context header", vi = "Nhảy lên đầu khối ngữ cảnh hiện tại" },
  { key = "<C-Space>", cat = "LSP", en = "Trigger autocompletion menu", vi = "Kích hoạt popup menu gợi ý autocomplete" },
  { key = "<CR>", cat = "LSP", en = "Confirm selected completion", vi = "Xác nhận chọn gợi ý autocomplete" },

  -- Trouble: Diagnostics, Symbols & Quickfix
  { key = "<leader>xx", cat = "Trouble", en = "Toggle project diagnostics list (Trouble)", vi = "Xem danh sách lỗi toàn project dạng cây (Trouble)", action = "Trouble diagnostics toggle" },
  { key = "<leader>xX", cat = "Trouble", en = "Toggle current buffer diagnostics (Trouble)", vi = "Xem danh sách lỗi file hiện tại (Trouble)", action = "Trouble diagnostics toggle filter.buf=0" },
  { key = "<leader>cs", cat = "Trouble", en = "Toggle symbols outline tree (Trouble)", vi = "Xem cây cấu trúc hàm/biến (Trouble Symbols)", action = "Trouble symbols toggle" },
  { key = "<leader>cl", cat = "Trouble", en = "Toggle LSP definitions & references (Trouble)", vi = "Xem định nghĩa và tham chiếu LSP (Trouble)", action = "Trouble lsp toggle" },
  { key = "<leader>xQ", cat = "Trouble", en = "Toggle quickfix list (Trouble)", vi = "Xem danh sách Quickfix dạng cây (Trouble)", action = "Trouble qflist toggle" },

  -- Git: LazyGit, Diffview, Conflicts & Hunks
  { key = "<leader>gg", cat = "Git", en = "Open LazyGit interactive TUI", vi = "Mở giao diện LazyGit nổi tương tác", action = "LazyGit" },
  { key = "<leader>gf", cat = "Git", en = "Open LazyGit for current file", vi = "Mở LazyGit cho file hiện tại", action = "LazyGitCurrentFile" },
  { key = "<leader>gd", cat = "Git", en = "Open Diffview side-by-side review", vi = "Mở xem so sánh Diffview hai cột", action = "DiffviewOpen" },
  { key = "<leader>gD", cat = "Git", en = "Close Diffview review", vi = "Đóng xem so sánh Diffview", action = "DiffviewClose" },
  { key = "<leader>gh", cat = "Git", en = "View current file git commit history", vi = "Xem lịch sử commit của file hiện tại", action = "DiffviewFileHistory %" },
  { key = "<leader>gH", cat = "Git", en = "View branch git commit history", vi = "Xem lịch sử commit toàn nhánh", action = "DiffviewFileHistory" },
  { key = "<leader>gc", cat = "Git", en = "Search git commits (Telescope)", vi = "Tìm kiếm danh sách commit (Telescope)", action = "Telescope git_commits" },
  { key = "<leader>gb", cat = "Git", en = "Checkout git branches (Telescope)", vi = "Chuyển / kiểm tra nhánh Git (Telescope)", action = "Telescope git_branches" },
  { key = "<leader>gs", cat = "Git", en = "Search git status files (Telescope)", vi = "Xem danh sách file thay đổi (Telescope)", action = "Telescope git_status" },
  { key = "<leader>gS", cat = "Git", en = "Search git stash entries (Telescope)", vi = "Xem danh sách git stash (Telescope)", action = "Telescope git_stash" },
  { key = "co", cat = "GitConflict", en = "Choose OURS / CURRENT change", vi = "Chọn thay đổi của BẢN THÂN (Ours)", action = "GitConflictChooseOurs" },
  { key = "ct", cat = "GitConflict", en = "Choose THEIRS / INCOMING change", vi = "Chọn thay đổi NHẬN VỀ (Theirs)", action = "GitConflictChooseTheirs" },
  { key = "cb", cat = "GitConflict", en = "Choose BOTH changes", vi = "Chọn CẢ HAI thay đổi (Both)", action = "GitConflictChooseBoth" },
  { key = "c0", cat = "GitConflict", en = "Choose NONE (delete conflict block)", vi = "Không chọn bên nào (Xóa trắng)", action = "GitConflictChooseNone" },
  { key = "]x / [x", cat = "GitConflict", en = "Jump to next / previous merge conflict", vi = "Nhảy tới xung đột merge tiếp / trước" },
  { key = "]c / [c", cat = "Git", en = "Jump to next / previous git change hunk", vi = "Nhảy tới đoạn code git thay đổi tiếp / trước" },
  { key = "<leader>hs", cat = "Git", en = "Stage current git hunk", vi = "Stage đoạn code thay đổi hiện tại", action = "Gitsigns stage_hunk" },
  { key = "<leader>hr", cat = "Git", en = "Reset / discard current git hunk", vi = "Hoàn tác / hủy bỏ đoạn code thay đổi hiện tại", action = "Gitsigns reset_hunk" },
  { key = "<leader>hp", cat = "Git", en = "Preview current git hunk diff", vi = "Xem trước khác biệt của đoạn code git", action = "Gitsigns preview_hunk" },
  { key = "<leader>hb", cat = "Git", en = "Show git blame line details", vi = "Xem chi tiết người sửa dòng này (Blame)", action = "Gitsigns blame_line" },
  { key = "<leader>tb", cat = "Git", en = "Toggle virtual line blame text", vi = "Bật/Tắt hiển thị git blame cuối dòng", action = "Gitsigns toggle_current_line_blame" },
  { key = "<leader>hS", cat = "Git", en = "Stage entire buffer", vi = "Stage toàn bộ thay đổi của file", action = "Gitsigns stage_buffer" },
  { key = "<leader>hR", cat = "Git", en = "Reset entire buffer", vi = "Hủy bỏ toàn bộ thay đổi của file", action = "Gitsigns reset_buffer" },
  { key = "<leader>hd", cat = "Git", en = "Diff current file against index", vi = "So sánh file hiện tại với git index", action = "Gitsigns diffthis" },

  -- Surround (Normal & Visual Modes + React/JSX)
  { key = "s{char}", cat = "Surround", en = "Visual: Wrap selection in char (s\", s', s(, s[, s{)", vi = "Visual: Bọc vùng chọn bằng ký tự (s\", s', s(, s[, s{)" },
  { key = "S{char}", cat = "Surround", en = "Visual: Wrap selection on new lines", vi = "Visual: Bọc vùng chọn xuống dòng mới" },
  { key = "st", cat = "Surround", en = "Visual: Wrap in HTML/JSX tag (<tag>...</tag>)", vi = "Visual: Bọc thẻ HTML/JSX (<tag>...</tag>)" },
  { key = "sf", cat = "Surround", en = "Visual: Wrap in React Fragment (<>...</>)", vi = "Visual: Bọc thẻ React Fragment (<>...</>)" },
  { key = "sc", cat = "Surround", en = "Visual: Wrap in JSX Comment ({/* ... */})", vi = "Visual: Bọc ghi chú JSX ({/* ... */})" },
  { key = "se", cat = "Surround", en = "Visual: Wrap in Template literal (${...})", vi = "Visual: Bọc biểu thức Template string (${...})" },
  { key = "sj", cat = "Surround", en = "Visual: Wrap in JSX brackets ({...})", vi = "Visual: Bọc biểu thức ngoặc JSX ({...})" },
  { key = "ys{motion}{c}", cat = "Surround", en = "Normal: Add surround (e.g. ysiw\")", vi = "Normal: Bọc ký tự quanh từ/khối (vd: ysiw\")" },
  { key = "ds{char}", cat = "Surround", en = "Normal: Delete surrounding delimiter (e.g. ds\")", vi = "Normal: Xóa ký tự bao quanh (vd: ds\")" },
  { key = "cs{from}{to}", cat = "Surround", en = "Normal: Change surround delimiter (e.g. cs\"')", vi = "Normal: Đổi ký tự bao quanh (vd: cs\"')" },

  -- DevOps & Fullstack (Docker, GitHub, Database, REST API)
  { key = "<leader>kd", cat = "DevOps", en = "Open LazyDocker TUI (Containers & Pods)", vi = "Mở LazyDocker quản lý container/pod", action = "LazyDocker" },
  { key = "<leader>tk", cat = "DevOps", en = "Toggle cloak mask for .env secrets", vi = "Bật/Tắt che giấu mật khẩu secrets trong .env (Cloak)", action = "CloakToggle" },
  { key = "<leader>op", cat = "GitHub", en = "List GitHub Pull Requests (Octo)", vi = "Xem danh sách GitHub PR (Octo)", action = "Octo pr list" },
  { key = "<leader>oi", cat = "GitHub", en = "List GitHub Issues (Octo)", vi = "Xem danh sách GitHub Issues (Octo)", action = "Octo issue list" },
  { key = "<leader>oa", cat = "GitHub", en = "View GitHub Actions workflow runs (Octo)", vi = "Xem các lần chạy GitHub Actions (Octo)", action = "Octo actions" },
  { key = "<leader>db", cat = "Database", en = "Toggle Dadbod Database Manager UI", vi = "Bật/Tắt giao diện quản lý cơ sở dữ liệu (Dadbod)", action = "DBUIToggle" },
  { key = "<leader>rr", cat = "REST", en = "Run HTTP REST request under cursor (Kulala)", vi = "Thực thi request HTTP tại con trỏ (Kulala)" },
  { key = "<leader>ra", cat = "REST", en = "Run all HTTP REST requests in file (Kulala)", vi = "Thực thi toàn bộ request HTTP trong file (Kulala)" },
  { key = "<leader>ns", cat = "Fullstack", en = "Show package.json versions & updates", vi = "Xem phiên bản package trong package.json" },
  { key = "<leader>nu", cat = "Fullstack", en = "Update package.json dependency", vi = "Cập nhật dependency trong package.json" },

  -- Multi-Cursor (Vim Visual Multi)
  { key = "<C-n>", cat = "MultiCursor", en = "Select word / next occurrence", vi = "Chọn từ / từ trùng tiếp theo (Đa con trỏ)" },
  { key = "<leader>ma", cat = "MultiCursor", en = "Select all word occurrences", vi = "Chọn tất cả các vị trí trùng khớp" },
  { key = "<leader>mj", cat = "MultiCursor", en = "Add cursor down", vi = "Thêm con trỏ ở dòng dưới" },
  { key = "<leader>mk", cat = "MultiCursor", en = "Add cursor up", vi = "Thêm con trỏ ở dòng trên" },
  { key = "q / Q", cat = "MultiCursor", en = "Skip match / remove cursor in VM mode", vi = "Bỏ qua / xóa con trỏ trong VM mode" },

  -- Todo Comments & Search
  { key = "]t / [t", cat = "Todo", en = "Jump to next / previous TODO comment", vi = "Nhảy tới ghi chú TODO tiếp / trước" },
  { key = "<leader>ft", cat = "Telescope", en = "Find all TODO / FIXME comments", vi = "Tìm tất cả ghi chú TODO / FIXME trong project", action = "TodoTelescope" },

  -- Session Management
  { key = "<leader>qs", cat = "Session", en = "Restore project session", vi = "Khôi phục phiên làm việc trước đó" },
  { key = "<leader>ql", cat = "Session", en = "Restore last session", vi = "Khôi phục phiên làm việc gần nhất" },
  { key = "<M-e>", cat = "AutoPair", en = "Fast wrap expression in brackets/quotes", vi = "Bọc nhanh biểu thức vào ngoặc/nháy kép" },

  -- Neovide / GUI (VSCode & WebStorm Shortcuts)
  { key = "Ctrl+S", cat = "GUI", en = "Save file (VSCode style)", vi = "Lưu file nhanh (kiểu VSCode)", action = "w" },
  { key = "Ctrl+P", cat = "GUI", en = "Quick open file (VSCode style)", vi = "Mở file nhanh (kiểu VSCode)", action = "Telescope find_files" },
  { key = "Ctrl+B", cat = "GUI", en = "Toggle sidebar explorer (VSCode style)", vi = "Bật/Tắt sidebar file explorer (kiểu VSCode)", action = "NvimTreeToggle" },
  { key = "Ctrl+Shift+F", cat = "GUI", en = "Global grep project search (VSCode style)", vi = "Tìm kiếm toàn bộ project (kiểu VSCode)", action = "Telescope live_grep" },
  { key = "Ctrl+Shift+P", cat = "GUI", en = "Command Palette (VSCode style)", vi = "Mở Command Palette (kiểu VSCode)", action = "Telescope keymaps" },
  { key = "Alt+Up / Down", cat = "GUI", en = "Move line / block up or down (VSCode style)", vi = "Di chuyển dòng/khối lên hoặc xuống (kiểu VSCode)" },
  { key = "Ctrl+= / Ctrl+-", cat = "GUI", en = "Zoom in / Zoom out GUI scale", vi = "Phóng to / thu nhỏ giao diện Neovide" },
}

function M.show(opts)
  opts = opts or {}
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("Telescope is required for Cheatsheet", vim.log.levels.ERROR)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local displayer = entry_display.create({
    separator = " │ ",
    items = {
      { width = 14 },
      { width = 11 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    local item = entry.value
    return displayer({
      { item.key, "TelescopeResultsIdentifier" },
      { "[" .. item.cat .. "]", "TelescopeResultsComment" },
      { item.en .. "  •  " .. item.vi },
    })
  end

  pickers.new(opts, {
    prompt_title = "Cheatsheet (English & Tiếng Việt)",
    finder = finders.new_table({
      results = M.items,
      entry_maker = function(item)
        local search_str = string.format("%s %s %s %s", item.key, item.cat, item.en, item.vi)
        return {
          value = item,
          display = make_display,
          ordinal = search_str,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value and selection.value.action then
          if type(selection.value.action) == "function" then
            pcall(selection.value.action)
          elseif type(selection.value.action) == "string" then
            pcall(vim.cmd, selection.value.action)
          end
        end
      end)
      return true
    end,
  }):find()
end

-- Register user command
vim.api.nvim_create_user_command("Cheatsheet", function()
  M.show()
end, { desc = "Show interactive bilingual cheatsheet" })

return M
