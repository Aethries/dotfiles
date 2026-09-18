# Kế hoạch xây dựng Neovim/Neovide/Antigravity IDE đồng bộ hoàn toàn

## 1. Mục tiêu bắt buộc

Xây dựng một môi trường IDE hoàn chỉnh cho fullstack engineering, DevOps và Git nâng cao với các đặc tính sau:

1. Neovim terminal, Neovide và Antigravity dùng chung một nguồn cấu hình trong repository này.
2. Antigravity sử dụng `asvetliakov.vscode-neovim`, chạy Neovim thật làm backend. Không cài hoặc sử dụng `vscodevim.vim` hay bất kỳ Vim emulator nào.
3. Toàn bộ keymap chỉnh sửa code được khai báo một lần trong Lua và được nạp trực tiếp ở cả Neovim, Neovide và Antigravity.
4. Một máy mới chỉ cần clone repository và chạy entrypoint build. Build phải cài hệ thống, kích hoạt user configuration, cài extension/plugin đã pin, sinh theme và chạy kiểm tra hậu cài đặt.
5. Không phụ thuộc username, home directory, đường dẫn máy cá nhân hoặc vị trí clone cố định.
6. Noctalia là nguồn duy nhất cho palette, mode và theme. Consumer không chứa tên scheme/theme hoặc mã màu cố định.
7. Tất cả dependency, plugin, extension và tool phải được khai báo, pin và có thể tái tạo từ repository cùng lock files.
8. Tất cả script phải có static checks, test hành vi, test lỗi và smoke test end-to-end.
9. Kiểm thử và xác thực script bắt buộc thực thi trong môi trường ảo hóa biệt lập (NixOS VM / Bubblewrap sandbox); tuyệt đối không chạy script thử nghiệm gây side-effect trực tiếp lên máy thật.
10. Đồng bộ ngữ cảnh và quy tắc phát triển của AI Agent giữa Neovim và Antigravity (JetSki).

## 2. Định nghĩa “đồng bộ 100%”

Repository phải quản lý 100% các thành phần có chủ đích sau:

- Neovim options, autocmds, keymaps, commands và plugin specifications.
- Phiên bản Neovim, Neovide, Antigravity, language servers, formatters, linters, debug adapters và CLI tools.
- Danh sách, phiên bản và checksum của Antigravity extensions.
- Antigravity settings, keybindings, snippets, profiles có chủ đích và extension recommendations.
- Keymap manifest, action mapping giữa native Neovim và Antigravity.
- Noctalia config, local templates, palette generation pipeline và consumer adapters.
- Git config, terminal integration, task definitions và project/worktree workflow.
- Bootstrap, activation, migration, validation, doctor và test suite.
- Tài liệu sử dụng, compatibility matrix và recovery procedure.

Các thành phần sau là runtime state và không được commit trực tiếp:

- Cache, log, crash report, lock file và compiled cache.
- Window/session history, recent files và workspace storage.
- Extension runtime database do Antigravity tự sinh.
- OAuth token, API key, SSH key, cookies và credential store.

Secret cần di chuyển giữa các máy phải nằm trong vault mã hóa. Build không được ghi secret vào Nix store, Git history hoặc output log. Sau khi restore vault, cấu hình chức năng phải giống nhau; người dùng có thể vẫn phải đăng nhập lại nếu provider không cho phép di chuyển token an toàn.

## 3. Kiến trúc nguồn duy nhất

### 3.1 Neovim

```text
resources/nvim/
├── init.lua
├── lazy-lock.json
└── lua/
    ├── config/
    │   ├── env.lua
    │   ├── actions.lua
    │   ├── keymaps.lua
    │   ├── options.lua
    │   ├── autocmds.lua
    │   └── health.lua
    ├── keymaps/
    │   ├── manifest.lua
    │   └── generated-doc.md
    └── plugins/
        ├── shared.lua
        ├── editor.lua
        ├── ui.lua
        ├── treesitter.lua
        ├── lsp.lua
        ├── completion.lua
        ├── formatting.lua
        ├── git.lua
        ├── dap.lua
        ├── test.lua
        └── devops.lua
```

`manifest.lua` là nguồn duy nhất cho keymap với schema cấu trúc hóa:
```lua
{
  key = "<leader>ff",
  mode = "n",
  action = "file.find",
  native = "Snacks.picker.files()",
  vscode = "workbench.action.quickOpen",
  desc = "Find Files",
  group = "file",
  scope = "editor" -- "editor" | "global_host"
}
```

- Native Neovim: Đăng ký trực tiếp `manifest.lua` vào `which-key.nvim` specs (zero trùng lặp code).
- Antigravity backend (`vim.g.vscode`): Fast-path ngay đầu `init.lua` — chỉ nạp `manifest.lua`, `actions.lua` và text-objects (`mini.ai`, `mini.surround`, `spider`). Bỏ qua 100% UI, LSP, Blink.cmp, Conform, Treesitter syntax highlight.
- Dòng 1 của `init.lua` kích hoạt `vim.loader.enable()` để tối ưu bytecode cache (startup < 50ms).
- Plugin reproducibility: `lazy.nvim` giữ lockfile `lazy-lock.json`. Quá trình build/activation chạy lệnh prefetch bắt buộc: `nvim --headless "+Lazy! restore" +qa` để đảm bảo lần mở editor đầu tiên hoàn toàn offline, đáp ứng R06.

### 3.2 Antigravity

```text
resources/antigravity/
├── product.json
├── workbench.html
├── workbench-jetski-agent.html
├── custom.css
├── extensions.lock.json
├── User/
│   ├── settings.jsonc
│   ├── keybindings.generated.jsonc
│   └── snippets/
└── generated/
    └── noctalia-theme.json
```

- Đường dẫn cấu hình: Chuẩn hóa thống nhất theo XDG (`~/.config/antigravity/User` hoặc symlink chuẩn hóa từ `~/.antigravity-ide/User`).
- Antigravity tìm `nvim` qua `PATH` và dùng config mặc định qua `stdpath("config")`. Settings không chứa absolute path đến executable hoặc `init.lua`.
- `keybindings.generated.jsonc`: Generator Lua CLI đọc các entry có `scope = "global_host"` từ `manifest.lua` để sinh ra keybindings cho host context (Terminal, Sidebar, JetSki Agent panel, QuickOpen, Window navigation) kèm `when` clauses phù hợp. Khai báo passthrough cho `<Space>`, `<C-w>`, `<C-p>`.
- `extensions.lock.json`: Chỉ áp dụng cho third-party extensions (như `asvetliakov.vscode-neovim`), chứa id, version, source và checksum. Không can thiệp vào built-in core extensions của Antigravity/JetSki.
- Live theme reload: Antigravity không bắt POSIX signal; áp dụng theme qua File Watcher của local theme extension đọc `generated/noctalia-theme.json` và inject CSS variables vào `custom.css` để Monaco tự động hot-reload mà không cần restart window.

### 3.2.1 Google Antigravity 2.0 (Desktop Orchestration App)

- **Package**: `antigravity` (từ `antigravityFlake.packages.${system}.google-antigravity`, binary `antigravity`, desktop entry `antigravity.desktop`).
- **Phân biệt với Antigravity IDE**: Antigravity 2.0 là desktop app độc lập (Electron) quản lý và điều phối Agent, Chat Canvas, Scheduled Tasks, Auxiliary Pane (Subagents, Artifacts, Terminals), độc lập khỏi editor.
- **MCP Configuration**: Tự động liên kết `resources/gemini/mcp_config.json` sang cả `~/.gemini/config/mcp_config.json` và `~/.gemini/antigravity/mcp_config.json`.
- **Runtime State & Conversations Sync**: Dữ liệu phiên làm việc (`~/.gemini/antigravity/conversations/`, `brain/`, `html_artifacts/`) được đồng bộ bảo mật qua `scripts/vault.sh` (mã hóa Zero-Knowledge `secrets.vault`).
- **Niri Window Management**: `Mod+Ctrl+A` mở hoặc focus nhanh Antigravity 2.0; tỉ lệ cột 0.8 và opacity thống nhất theo Noctalia.

### 3.3 User activation

Chuyển quản lý user files sang cấu hình Nix/Home Manager tích hợp trong flake:

- Source files được Nix đưa vào store và liên kết vào đúng XDG/home location.
- Username và home directory lấy từ machine/user option, không xuất hiện trong source config.
- Không liên kết cả thư mục mutable của Antigravity. Chỉ quản lý từng settings, keybindings và snippets file.
- Runtime directories vẫn thuộc quyền ghi của user.
- Snapshot rollback tự động: Trước khi ghi đè hoặc link cấu hình, entrypoint build tự động tạo snapshot trạng thái vào `~/.cache/dotfiles/backup-latest/`. Nếu gặp lỗi ở bất kỳ bước nào, script lập tức rollback trạng thái cũ và báo diff.
- Activation phải atomic, idempotent và có migration/backup cho file unmanaged trước đó.

`scripts/build.sh` trở thành entrypoint duy nhất. Khi machine config chưa tồn tại, script tự gọi bước generate an toàn trước khi build. Sau khi rebuild, script chạy user activation, extension verification, theme generation và doctor.

## 4. Rule bắt buộc

### R01 — Không hardcode môi trường người dùng

- Không chứa home directory cụ thể, username cụ thể hoặc absolute path phụ thuộc máy.
- Shell dùng `$HOME`, `${XDG_CONFIG_HOME:-$HOME/.config}` và đường dẫn suy ra từ vị trí script.
- Lua dùng `vim.fn.stdpath()`, `vim.fn.expand()` và `vim.fs`.
- Nix dùng options và `config.home.homeDirectory`/user configuration.
- JSON settings ưu tiên command trong `PATH`; không trỏ vào `/run/current-system` nếu không cần thiết.

### R02 — Một nguồn cấu hình

- Không copy settings/profile rồi cho phép chúng phân kỳ.
- Không khai báo cùng semantic keymap trong Lua và JSON bằng tay.
- Không có default profile blob chứa bản sao settings/snippets.
- Generated file phải có header, generator và test freshness.

### R03 — Chỉ dùng Neovim extension trong Antigravity

- Extension bắt buộc: `asvetliakov.vscode-neovim`.
- Extension cấm: `vscodevim.vim` và các Vim emulators khác.
- Build/check phải phát hiện extension cấm trong manifest và installed extensions.
- `vim.g.vscode` là feature gate chính thức cho Antigravity backend.
- Triệt tiêu bloat: Khi `vim.g.vscode` bật, Neovim cấm nạp 100% UI, LSP, completion (`blink.cmp`), lint, format (`conform`) và treesitter highlight.

### R04 — Keymap parity 100%

- Cùng key, mode, mô tả và semantic result trên ba host.
- Action không có native API tương đương phải đi qua host adapter nhưng giữ nguyên key và kết quả người dùng nhìn thấy.
- Phân luồng ranh giới: `manifest.lua` phân tách `editor` (xử lý trong Neovim buffer) và `global_host` (sinh `keybindings.generated.jsonc` cho Terminal, Explorer, JetSki Agent, Window navigation) kèm passthrough `<Space>`, `<C-w>`, `<C-p>`.
- Keymap chỉ dành cho agent/UI Antigravity được đặt trong namespace riêng và không chiếm keymap editing chung.
- Mọi collision với terminal, Zellij, Niri, completion và snippets phải làm check thất bại.
- Keymap documentation được sinh từ manifest, không viết tay.
- Đồng bộ clipboard Wayland: Tích hợp `wl-copy`/`wl-paste` với OSC 52 fallback, đảm bảo sao chép mượt mà giữa Terminal, Neovim, Neovide và Antigravity.

### R05 — Noctalia là theme authority duy nhất

- Chỉ Noctalia config được phép chọn source, mode và palette.
- Neovim, Neovide, Antigravity, terminal và Git UI chỉ đọc output/token do Noctalia sinh.
- Xóa mã màu cố định khỏi Neovim theme module và app-specific theme configuration.
- Không pin tên colorscheme trong consumer settings.
- Local Noctalia templates dùng semantic tokens như background, surface, primary, error và on-surface.
- Theme apply phải atomic: Phát `SIGUSR1` cho Neovim/Neovide, và cập nhật `generated/noctalia-theme.json` kèm CSS variables trong `custom.css` cho Antigravity (Antigravity tự động reload theme qua file watcher, không restart window).
- Nếu generation thất bại, giữ output hợp lệ gần nhất và trả exit code khác 0; không sinh file dở dang.

### R06 — Dependency reproducibility

- Tất cả Nix inputs nằm trong `flake.lock`.
- Neovim plugin commit nằm trong lock file và được prefetch bắt buộc trong build/activation (`nvim --headless "+Lazy! restore" +qa`); lần mở editor đầu tiên không được download.
- Antigravity VSIX bên thứ ba phải pin version và checksum bằng fixed-output derivation hoặc manifest; không áp dụng cho core/internal agent extensions.
- Language server/debug adapter/formatter lấy từ Nix hoặc project dev shell đã pin.
- Không cài global npm/pip/go package ngầm trong editor startup.

### R07 — Host ownership rõ ràng

- Trong native Neovim: Neovim sở hữu UI, LSP, completion, diagnostics, formatter, debugger, tests và Git UI.
- Trong Antigravity: host sở hữu các IDE surface trên; Neovim sở hữu modal editing và shared semantic keymaps.
- Native-only plugin phải có `cond = not vim.g.vscode` hoặc nằm trong native import.
- Không cho hai formatter, LSP client hoặc diagnostics provider cùng xử lý một buffer.

### R08 — Format/lint deterministic

- Project-local config thắng global defaults.
- Với web: Biome khi có Biome config; Prettier khi có Prettier config; ESLint fix chỉ khi project yêu cầu.
- Mỗi save chỉ một formatter được phép ghi buffer.
- Indentation fallback dùng EditorConfig và quy ước chung; language/project override phải rõ ràng.
- Format failure phải hiển thị tool, command và file liên quan.

### R09 — Script quality

- Mọi script dùng strict mode phù hợp và quote biến đường dẫn.
- Không dùng `eval` để xây command.
- Không nuốt lỗi của bước bắt buộc.
- Mutation phải có target cụ thể, validation trước, atomic write và rollback/backup khi cần.
- Script destructive phải có dry-run hoặc explicit action rõ ràng.
- Script phải chạy được khi repo path chứa khoảng trắng.
- Chạy lại hai lần phải cho cùng kết quả và không tạo file rác.

### R10 — Security và privacy

- Không log secret hoặc environment nhạy cảm.
- Không đưa credential vào Nix derivation/store.
- Repository chỉ chứa public config và encrypted vault.
- Agent/extension permissions phải được khai báo ở mức tối thiểu cần thiết.
- File sinh từ workspace không được tự động thêm vào Git nếu chưa được kiểm tra.

### R11 — Performance budget

- Native cold startup mục tiêu dưới 50 ms (bật `vim.loader.enable()`).
- Antigravity Neovim backend ready mục tiêu dưới 100 ms (nhờ bypass hoàn toàn plugin không cần thiết).
- Big-file mode tắt parser, diagnostics và expensive UI theo ngưỡng có cấu hình.
- Plugin phải lazy-load theo event/key/command trừ core bắt buộc.
- Performance regression vượt 20% làm full check thất bại hoặc yêu cầu ghi nhận lý do.

### R12 — Compatibility và upgrade

- Ghi rõ minimum/verified version của Neovim, Neovide và Antigravity.
- Dùng API LSP hiện hành của Neovim 0.12.
- Upgrade lock file phải chạy full integration suite.
- Patch vào internals của Antigravity phải có compatibility check theo build/version và fail rõ ràng nếu upstream layout thay đổi.

### R13 — Kiểm thử môi trường ảo biệt lập (Isolated Execution Safety)

- Tuyệt đối không chạy script kiểm thử, script cài đặt thử nghiệm hoặc migration trực tiếp lên máy thật.
- Mọi script và thay đổi cấu hình phải được thẩm định và xác thực trong môi trường ảo hóa biệt lập (NixOS VM hoặc Bubblewrap tmpfs sandbox `scripts/test-isolated.sh`) trước khi áp dụng vào hệ thống chính.
- Mọi script kiểm thử khi hoàn tất phải đảm bảo 100% exit code 0, không có lỗi tiềm ẩn và không để lại file rác ngoài sandbox.

## 5. IDE feature stack

### Editing và navigation

- Treesitter cho parsing và text objects.
- `nvim-spider`, `mini.ai`, `mini.surround` cho editing primitives.
- Snacks cho picker, explorer, projects, terminal, notifications và big-file protection.
- Which-key sinh nhóm từ keymap manifest (native).
- Autopairs chỉ bật ở native Neovim; Antigravity dùng host pair handling.
- Window & Split navigation hợp nhất: `<C-h/j/k/l>` điều hướng liền mạch giữa Neovim splits / Zellij panes ở terminal, và các editor groups / side panels trong Antigravity.

### Language intelligence

- Native LSP bằng `vim.lsp.config()`/`vim.lsp.enable()` và nvim-lspconfig data.
- Blink.cmp stable cho completion native.
- Conform cho formatting; nvim-lint cho non-LSP lint.
- Trouble cho diagnostics, references và quickfix.
- Toolchain core: TypeScript/JavaScript/React/NestJS, Go, Nix, Lua, Bash, HTML/CSS/JSON, YAML, TOML và Markdown.
- Toolchain DevOps: Docker/Compose, Kubernetes, Helm, Terraform/OpenTofu, GitHub Actions và Ansible khi được bật.

### Git nâng cao

- Gitsigns cho hunks và blame.
- Diffview cho repository diff, file history và merge conflict.
- Lazygit cho interactive stage, rebase, cherry-pick và stash.
- `gh`/`gh-dash` cho pull requests và actions.
- Worktree picker dựa trên Git porcelain output, không parse output dành cho người đọc.
- Tích hợp sâu vào `scripts/pj.sh`: Thêm hotkey `Ctrl+W` mở worktree switcher trực tiếp, mở đúng worktree path trong Antigravity hoặc Neovim.
- Git config bổ sung rerere, autosquash, autostash, updateRefs, pruneTags, verbose commit và histogram diff sau khi có behavioral tests.

### Debug, test và task

- nvim-dap cùng UI cho native Neovim.
- Delve cho Go và vscode-js-debug adapter cho JS/TS.
- Neotest cho Go, Jest và Vitest.
- Task runner phát hiện package scripts, Makefile, Taskfile và project-local commands.
- Antigravity map cùng key sang Debug, Testing và Tasks APIs của host.

### AI Agent và Context Parity

- Neovim terminal CLI $\leftrightarrow$ Antigravity JetSki Agent (`workbench-jetski-agent.html`).
- Đồng bộ tự động các tệp quy tắc hướng dẫn AI (`CLAUDE.md`, `.cursorrules`, `.gemini/rules`) từ repository vào workspace.
- Hotkey thống nhất (`<leader>aa`): Mở JetSki Agent panel trong Antigravity, mở floating terminal runner trong Neovim.

## 6. Các phase triển khai

### Phase 0 — Baseline, test harness và môi trường ảo hóa

- Thiết lập harness kiểm thử biệt lập: Viết `scripts/test-isolated.sh` (dùng Bubblewrap hoặc `tmpfs` mktemp cô lập `$HOME`, `$XDG_CONFIG_HOME`) và khai báo NixOS VM runner (`nixosConfigurations.test.config.system.build.vm`) trong `flake.nix`.
- Chụp inventory version, extensions, settings và current keymaps.
- Tạo fixture cho unmanaged user files và migration test.
- Ghi startup baseline và functional checklist.

Exit gate: baseline lưu trong test artifacts; toàn bộ test harness chạy được trong môi trường ảo biệt lập; working tree và máy thật không bị sửa.

### Phase 1 — Nix/Home Manager và single-build activation

- Thêm user option không phụ thuộc username.
- Quản lý toàn bộ intended home files từ Nix.
- Hợp nhất bootstrap vào build entrypoint kèm cơ chế snapshot rollback tự động trước khi ghi cấu hình.
- Tách mutable Antigravity state khỏi declarative files.

Exit gate: kiểm thử 100% bằng temporary HOME và NixOS VM; chạy build hai lần liên tiếp không có drift, exit code 0.

### Phase 2 — Antigravity extension lock và config migration

- Tạo extension lock manifest cho user extensions.
- Pin/fetch/install VSIX trong build mà không can thiệp built-in core extensions.
- Di chuyển settings, snippets và profile source vào repo theo đường dẫn XDG chuẩn.
- Xóa hardcoded paths và duplicated default profile blob.

Exit gate: clean machine fixture có đúng extension set; extension cấm vắng mặt; offline editor startup không download dependency; script chạy sạch trong sandbox.

### Phase 3 — Shared keymap/action architecture

- Tạo manifest và host adapter.
- Chuyển toàn bộ keymap hiện tại.
- Sinh Antigravity routing JSON (`keybindings.generated.jsonc`) cho host context và documentation.
- Thêm schema contract validation tests và collision checks.

Exit gate: 100% shared semantic actions vượt qua schema validator; manifest không trùng lặp phím; routing JSON sinh chính xác.

### Phase 4 — Noctalia theme pipeline

- Vendor/localize templates cần thiết trong repo.
- Sinh Neovim Lua palette và Antigravity theme tokens từ cùng Noctalia palette.
- Cấu hình hot-reload: `SIGUSR1` cho Neovim/Neovide, Theme Extension File Watcher & CSS variables cho Antigravity.
- Thêm last-known-good rollback khi sinh theme lỗi.
- Xóa consumer color/theme hardcode.

Exit gate: đổi wallpaper/mode một lần cập nhật cả Neovim, Neovide và Antigravity; theme lint không phát hiện hardcode ngoài source/template fixtures.

### Phase 5 — Native IDE editing, UI và search

- Thêm Treesitter, Snacks, text objects, surround, Which-key và status UI.
- Thêm `vim.loader.enable()` cho startup < 50ms.
- Chuyển lazy.nvim sang event-driven specs; thêm fast-path bypass cho Antigravity.
- Thêm big-file behavior.

Exit gate: startup/performance budget đạt; file/search/project/buffer workflows pass.

### Phase 6 — LSP, completion, formatting và lint

- Khai báo Nix toolchain.
- Thiết lập native LSP và project root detection.
- Thiết lập deterministic formatter selection.
- Map semantic actions sang Antigravity host; đảm bảo Antigravity không chạy đúp LSP/formatter từ Neovim backend.

Exit gate: language matrix mở file, diagnostics, hover, goto, references, rename, action và format đều pass; không duplicate provider.

### Phase 7 — Git nâng cao và Worktree

- Cấu hình Gitsigns, Diffview, Lazygit và worktree picker.
- Tích hợp Git worktree switcher vào `scripts/pj.sh` (`Ctrl+W`).
- Nâng Git config và aliases.
- Map cùng namespace sang Antigravity SCM/GitLens/terminal.

Exit gate: stage hunk, amend, fixup/autosquash, rebase, bisect, stash, cherry-pick, worktree và conflict resolution pass trên repository fixture.

### Phase 8 — Debug, tests, tasks, DevOps và AI Parity

- Thêm DAP, Neotest và task runner.
- Thêm Docker, Kubernetes, Helm và Terraform toolchain/actions.
- Đồng bộ ngữ cảnh quy tắc AI Agent (`CLAUDE.md`, `.cursorrules`, `.gemini/rules`) giữa Neovim và Antigravity JetSki.
- Map cùng keys sang host APIs.

Exit gate: debug/test TS và Go; lint/validate Dockerfile, workflow, Kubernetes/Helm và Terraform fixtures.

### Phase 9 — Full validation trong môi trường ảo và documentation

- Chạy toàn bộ static checks, unit tests và integration tests trong sandbox biệt lập.
- Chạy new-machine rehearsal từ clean checkout bên trong NixOS Headless VM.
- Sinh keymap/toolchain docs tự động.

Exit gate: toàn bộ Definition of Done đạt; 100% script chạy thành công không có lỗi; không có skipped critical test.

## 7. Test strategy bắt buộc

### 7.1 Static checks

- `bash -n` và ShellCheck cho mọi shell script (`scripts/*.sh`).
- nixfmt và `nix flake check --no-build` cho mọi Nix file.
- Stylua (`stylua --check`) và LuaCheck cho Lua code.
- JSON/JSONC/TOML/KDL validation.
- Scanner cấm user-specific absolute paths.
- Scanner cấm consumer theme names và literal color values.
- Scanner cấm Vim emulator extension IDs.
- Generated-file freshness check.

### 7.2 Thực thi kiểm thử trong Sandbox cô lập (`scripts/test-isolated.sh`)

Sử dụng Bubblewrap (`bwrap`) hoặc `tmpfs` mktemp cô lập hoàn toàn môi trường chạy:
- Tạo `MOCK_HOME` và `MOCK_XDG` tạm thời, tự động dọn sạch sau khi thoát (trap EXIT).
- Mock các dependency bên ngoài khi cần thiết; tuyệt đối KHÔNG chạy mutation lên host `$HOME`.
- Kiểm thử toàn diện các script:
  - `bootstrap.sh`: fresh machine, existing config, broken link, path có khoảng trắng, rerun idempotency.
  - `build.sh`: mọi action hợp lệ/sai, missing machine config, failed rebuild rollback và successful activation.
  - `sync-noctalia.sh`: valid palette, invalid output, daemon unavailable, atomic rollback và signal reload.
  - `doctor.sh`: healthy state, missing tool, wrong symlink, failed service và exit code chính xác.
  - `pj.sh`: editor selection, worktree picker `Ctrl+W`, invalid directory và project path có khoảng trắng.
  - `vault.sh`: dry-run, encrypted round trip, exclude rules và không log secret.
  - `flakify.sh`: từng template sinh flake hợp lệ và không overwrite ngoài contract.

### 7.3 Neovim tests

- Headless startup với clean HOME/XDG trong sandbox (`nvim --headless "+Lazy! restore" +qa`).
- Assert plugin lock và no-download first startup sau build.
- Contract validation: Assert keymap manifest schema hợp lệ, không duplicate key, action names khớp catalog.
- Assert native actions resolve chính xác.
- Open fixtures cho từng language và kiểm tra LSP attach/root/capabilities.
- Formatter selection table tests.
- Git fixture tests cho hunks, diff, history và conflicts.
- DAP/test adapter configuration smoke tests.

### 7.4 Antigravity tests

- Validate settings/keybindings JSONC.
- Verify installed extensions đúng chính xác lock manifest.
- Verify `vscode-neovim` khởi động với `nvim` từ PATH và default config.
- Verify Vim emulator không được cài/enabled.
- So sánh generated host routing với keymap manifest.
- Smoke test cho editor, terminal, explorer, agent panel, diff, debug và test views.

### 7.5 Theme tests

- Sinh hai palette fixture khác nhau và xác nhận mọi consumer output thay đổi tương ứng.
- Không consumer nào giữ literal colors/tên theme cũ.
- Reload không yêu cầu restart Neovim/Neovide nếu ứng dụng hỗ trợ live reload; Antigravity hot-reload qua theme file watcher / CSS variables.
- Invalid generation giữ last-known-good files.

### 7.6 New-machine acceptance test trên NixOS Headless VM

Kiểm thử toàn trình độc lập trên NixOS Headless QEMU VM (`nix build .#nixosConfigurations.test.config.system.build.vm`):

1. Clone repository trong VM.
2. Chạy một build entrypoint duy nhất (`./scripts/build.sh`).
3. Xác nhận không có lỗi tải mạng ngoài ý muốn (offline test).
4. Mở Neovim, Neovide và Antigravity trong VM.
5. Chạy fullstack, Go, Git-conflict và DevOps fixture workflows.
6. Chạy doctor và full check $\rightarrow$ exit code 0.
7. Chạy build lần hai và xác nhận không có drift (idempotent).

## 8. Definition of Done

Chỉ được xem là hoàn tất khi toàn bộ điều kiện sau cùng đúng:

- Repository là nguồn duy nhất cho mọi intended config và dependency version.
- Toàn bộ script và thay đổi cấu hình được kiểm thử thành công 100% trong môi trường ảo hóa biệt lập (NixOS VM / Sandbox), exit code 0, không có bất kỳ lỗi cú pháp hoặc runtime nào.
- Tuyệt đối không có mutation ngoài ý muốn hay làm hỏng môi trường phát triển trên máy thật.
- Clean-machine build tạo được môi trường dùng ngay.
- Không có user-specific hardcode.
- Không có consumer theme/scheme/color hardcode.
- Antigravity chỉ dùng Neovim extension cho Vim/Neovim behavior; cấm hoàn toàn bloatware nạp chồng chéo.
- Keymap semantic parity đạt 100% và có automated schema proof.
- Không duplicate LSP, diagnostics hoặc formatting.
- Extension/plugin first launch không tải dependency ngầm.
- Tất cả script static checks và behavior tests pass 100%.
- Fullstack, Go, Git advanced và DevOps acceptance matrix pass.
- Build và activation idempotent.
- Performance budgets đạt: Native startup < 50ms, Antigravity backend ready < 100ms.
- `doctor` và full validation trả exit code 0.
- Không sửa hoặc xóa unrelated user data trong migration.
- Mọi giới hạn còn lại được ghi thành issue rõ ràng; không dùng skipped critical test để tuyên bố hoàn tất.

## 9. Trình tự commit đề xuất

1. `test: establish reproducibility and migration harness`
2. `refactor(nix): add declarative user activation`
3. `feat(antigravity): pin extensions and manage user config`
4. `refactor(nvim): introduce shared action and keymap manifest`
5. `feat(theme): make noctalia the single palette authority`
6. `feat(nvim): add editing navigation and project UI`
7. `feat(nvim): add language intelligence and deterministic formatting`
8. `feat(git): add advanced git and worktree workflows`
9. `feat(ide): add debugging testing tasks and devops tooling`
10. `test: complete clean-machine and cross-host acceptance suite`

Mỗi commit phải pass checks thuộc phạm vi của nó. Commit cuối phải pass full suite và clean-machine rehearsal.
