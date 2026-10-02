# Kế hoạch 11: Hệ Sinh Thái AI Developer Tooling và Quy Trình Agentic Engineering

## 1. Tên chức năng
**Tối Ưu Hóa Môi Trường Lập Trình Với AI: Tích Hợp AG Kit, Ponytail YAGNI, RTK Ultra Token Compression, Caveman Mode, CodeGraph MCP và Codebase MCP.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* **Hao phí Token và Tràn Context Window:** Output terminal dài từ các lệnh build, test, linter hoặc lỗi stacktrace nuốt cạn giới hạn context của LLM khi chạy các agent tự động.
* **Over-engineering và "Code Slop":** Các mô hình AI thường có xu hướng tự ý thêm các lớp abstraction không cần thiết, tự sinh boilerplate, hoặc tạo file cấu hình cho các giá trị không đổi.
* **Giao tiếp rườm rà:** Phản hồi từ AI chứa nhiều từ nối xã giao, giải thích dài dòng làm chậm chu kỳ pair programming tốc độ cao.
* **Thiếu hiểu biết cấu trúc Codebase cục bộ:** Khi cần review hoặc refactor một module lớn, agent phải đọc hàng chục file mã nguồn thô thay vì tra cứu nhanh đồ thị phụ thuộc (AST graph blast radius).
* **Phân mảnh cấu hình công cụ:** Cấu hình MCP server và agent prompt chưa được chuẩn hóa đồng bộ giữa Antigravity IDE và Gemini CLI ngoài terminal.

### 2.2. Mục tiêu kỹ thuật
1. **AG Kit (`.agents/`):**
   * Chuẩn hóa cấu trúc thư mục quy tắc của workstation: `.agents/agent/`, `.agents/skills/`, `.agents/rules/`, `.agents/memory/`.
   * Thiết lập cơ chế memory cross-session ghi nhớ convention dự án và quyết định kiến trúc bền vững.
2. **Ponytail Principle (Senior YAGNI):**
   * Định hình tiêu chuẩn lập trình tối giản: ưu tiên xóa code hơn viết mới, tận dụng tối đa stdlib và abstraction sẵn có.
   * Quy định mọi giản lược có chủ đích phải gắn cờ `ponytail:` ghi rõ giới hạn và lộ trình nâng cấp.
3. **RTK Ultra (Terminal Stream Token Filter):**
   * Bộ lọc thông minh cho output của bash/zsh: tự động cắt giảm log dư thừa, lọc stack trace tập trung, nén 60-80% token tiêu hao trước khi đưa vào ngữ cảnh mô hình.
4. **Caveman Communication:**
   * Giao thức phản hồi cô đọng tối đa (telegraphic): `[đối tượng] [hành động] [nguyên nhân]. [bước tiếp theo].` Loại bỏ hoàn toàn câu chào hỏi rườm rà.
5. **CodeGraph MCP:**
   * Cung cấp MCP server chạy ngầm phân tích AST bằng Tree-sitter kết hợp SQLite database.
   * Cho phép agent truy vấn blast radius (phạm vi ảnh hưởng cấu trúc) của một thay đổi hàm/lớp mà không cần duyệt toàn bộ file.
6. **Codebase MCP:**
   * Cung cấp MCP server lập chỉ mục ký hiệu (symbols, functions, classes), phục vụ tìm kiếm ngữ nghĩa và tra cứu định nghĩa nhanh.

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[NEW]** `modules/antigravity/files/mcp_config.json`: Cấu hình danh mục MCP servers chuẩn cho workstation.
* **[MODIFY]** [modules/antigravity/setup.sh](file:///home/loc/Workspaces/dotfiles/modules/antigravity/setup.sh): Tự động liên kết MCP config vào Antigravity IDE và Gemini CLI (`~/.gemini/antigravity-cli/mcp_config.json`).
* **[NEW]** `modules/shell/files/bin/rtk`: Utility script lọc và nén output lệnh terminal trước khi chuyển cho agent.
* **[MODIFY]** [modules/shell/files/.zshrc](file:///home/loc/Workspaces/dotfiles/modules/shell/files/.zshrc): Bổ sung alias và helper cho RTK Ultra và AI workflows.
* **[MODIFY]** [.agents/memory/MEMORY.md](file:///home/loc/Workspaces/dotfiles/.agents/memory/MEMORY.md): Ghi nhận conventions về Ponytail, RTK Ultra, Caveman và cấu hình MCP.

### 3.2. Cấu hình MCP Server (`modules/antigravity/files/mcp_config.json`)

```json
{
  "mcpServers": {
    "codegraph": {
      "command": "uvx",
      "args": ["code-review-graph", "mcp"],
      "env": {}
    },
    "codebase": {
      "command": "uvx",
      "args": ["codebase-memory-mcp"],
      "env": {}
    }
  }
}
```

### 3.3. Tiêu chuẩn Agent Rules & Prompts

* **Ponytail YAGNI Standard:**
  ```markdown
  - Code ngắn nhất chạy được.
  - Tận dụng tính năng nền tảng và thư viện sẵn có.
  - Định dạng: [code] → skipped: [X], add when [Y].
  ```
* **Caveman Mode Standard:**
  ```markdown
  - Ultra-terse, telegraphic, loại bỏ liên từ.
  - Định dạng: [đối tượng] [hành động] [nguyên nhân]. [bước tiếp theo].
  ```
* **RTK Ultra Pipeline:**
  ```bash
  # Tự động tóm tắt output lớn khi chạy test/build
  cargo test 2>&1 | rtk summary
  npm test 2>&1 | rtk summary
  ```

---

## 4. Hướng dẫn sử dụng & Workflow

### 4.1. Thao tác với AG Kit & Chế độ Caveman

* Khi bắt đầu tác vụ phức tạp:
  ```bash
  # Khởi động agent với định hướng tối giản YAGNI
  /orchestrator thực hiện refactor module theo chuẩn ponytail
  ```
* Giao tiếp giữa người và agent:
  - Agent phản hồi ngắn gọn, đi thẳng vào nguyên nhân kỹ thuật và giải pháp.
  - Mọi diff đều ở mức tối thiểu (minimal working diff).

### 4.2. Tra cứu Blast Radius bằng CodeGraph MCP

1. Khi sửa đổi một interface hoặc hàm dùng chung:
   - Agent tự động gọi công cụ `codegraph` để kiểm tra các file chịu ảnh hưởng trực tiếp.
   - Không cần nạp toàn bộ repo vào bộ nhớ ngữ cảnh.
2. Tiết kiệm từ 50,000 đến 100,000 token cho mỗi lượt phân tích codebase lớn.

### 4.3. Tiết kiệm Token Terminal với RTK Ultra

* Sử dụng alias `rtk` để bọc các lệnh phát sinh output lớn:
  ```bash
  rtk git diff
  rtk npx vitest run
  ```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra MCP Servers:**
   * Khởi chạy Antigravity IDE và kiểm tra bảng điều khiển MCP Tools: `codegraph` và `codebase` hiển thị trạng thái `Connected`.
2. **Kiểm tra RTK Ultra Filter:**
   * Chạy thử lệnh sinh output dài qua `rtk`: dữ liệu được nén gọn, giữ nguyên stacktrace lỗi mà không tràn terminal.
3. **Kiểm tra tính nhất quán AG Kit:**
   * Mọi session làm việc mới đều tự động nạp cấu hình từ `.agents/rules/` và `.agents/memory/MEMORY.md`.
