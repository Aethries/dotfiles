# Kế hoạch 11: Hệ Sinh Thái AI Developer Tooling và Quy Trình Agentic Engineering

## 1. Tên chức năng
**Tối Ưu Hóa Môi Trường Lập Trình Với AI: Tích Hợp Bộ 10 Kỹ Năng Cốt Lõi (AG Kit, Superpowers, Ponytails, UI/UX Pro Max, Graphify, Caveman, Addy Osmani, Understand Anything, Archify, Impeccable) Cùng MCP Servers & RTK Ultra.**

---

## 2. Mô tả chức năng

### 2.1. Vấn đề hiện tại
* **Hao phí Token và Tràn Context Window:** Output terminal dài từ các lệnh build, test, linter hoặc lỗi stacktrace nuốt cạn giới hạn context của LLM khi chạy các agent tự động.
* **Over-engineering và "Code Slop":** Các mô hình AI thường có xu hướng tự ý thêm các lớp abstraction không cần thiết, tự sinh boilerplate, hoặc tạo file cấu hình cho các giá trị không đổi.
* **Giao diện Generic thiếu bản sắc:** Giao diện sinh bởi AI thường rập khuôn ("AI template slop"), thiếu hệ thống design tokens, typography scale và vi phạm các chuẩn mực tương tác người dùng.
* **Suy giảm Hiệu năng Web:** Code frontend sinh tự động thường bỏ qua các chỉ số Core Web Vitals (INP, LCP, CLS), lạm dụng JavaScript và thiếu tối ưu hóa tài nguyên tải.
* **Khó khăn khi tiếp cận Codebase lớn:** Agent tốn hàng chục ngàn token đọc mã nguồn thô thay vì tra cứu đồ thị quan hệ phụ thuộc (AST graph blast radius) và mô hình hóa kiến trúc nhanh.
* **Giao tiếp rườm rà:** Phản hồi từ AI chứa nhiều câu chào hỏi xã giao, giải thích dài dòng làm chậm chu kỳ pair programming tốc độ cao.
* **Thiếu tiêu chuẩn chất lượng nghiêm ngặt:** Code sinh ra thiếu strict typing, không có boundary validation ở các điểm tiếp nhận dữ liệu và dễ phát sinh lỗi tiềm ẩn.

### 2.2. Danh mục 10 Kỹ Năng Cốt Lõi (10 Agentic Skill Pillars)

1. **AG Kit (`.agents/`):**
   * Hệ sinh thái agentic nền tảng quản trị workstation: Persona chuyên gia (`.agents/agent/`), Thư viện kỹ năng modular (`.agents/skills/`), Bộ quy tắc chuẩn (`.agents/rules/`), và Bộ nhớ xuyên phiên (`.agents/memory/MEMORY.md`).
   * Phân quyền ưu tiên: P0 (Workspace Rules) > P1 (Agent Persona) > P2 (Skills).

2. **Superpowers (Agentic Meta-Workflows):**
   * Bộ quy trình vận hành tự động cấp cao: Socratic Gate (`brainstorming`), Lập kế hoạch theo giai đoạn (`plan-writing`), Quy trình TDD Red-Green-Refactor (`tdd-workflow`), 4 bước chẩn đoán nguyên nhân gốc rễ (`systematic-debugging`), Chứng minh code chạy trước khi bàn giao (`verify-changes`), và Điều phối agent song song (`parallel-agents`).

3. **Ponytails (Senior YAGNI Principle):**
   * Tiêu chuẩn lập trình tối giản cực hạn của senior developer: Xóa code trước khi viết thêm, ưu tiên stdlib và tính năng nền tảng native (CSS trên JS, DB constraint trên app code).
   * Mọi lược bỏ có chủ đích phải gắn cờ `ponytail:` ghi rõ trần giới hạn kỹ thuật và lộ trình mở rộng khi cần.

4. **UI/UX Pro Max (Design Intelligence & Anti-Slop):**
   * Chống thiết kế rập khuôn, kiến tạo giao diện chuẩn mực: Bắt buộc tác quyền tài liệu `DESIGN.md` trước khi code UI (design tokens, color palette, typography, component specs).
   * Đảm bảo chuẩn tiếp cận WCAG AA, responsive tự nhiên, tương tác xúc giác mượt mà và kiểm định audit trước khi bàn giao (`frontend-design`, `design-spec`, `web-design-guidelines`).

5. **Graphify (AST Knowledge Graph & Blast Radius):**
   * Phân tích cấu trúc mã nguồn bằng Tree-sitter kết hợp SQLite (`code-review-graph`).
   * Tính toán chính xác blast radius (phạm vi ảnh hưởng cấu trúc) của các thay đổi hàm/lớp/interface mà không cần nạp toàn bộ repo vào context window.

6. **Caveman Mode (Telegraphic Communication):**
   * Giao thức phản hồi cô đọng tối đa: `[đối tượng] [hành động] [nguyên nhân]. [bước tiếp theo].`
   * Loại bỏ hoàn toàn từ ngữ xã giao, liên từ thừa, giữ nguyên tên định danh code, đường dẫn file và lệnh terminal chính xác.

7. **Addy Osmani Skills (Web Performance & Modern Architecture):**
   * Tiêu chuẩn kỹ thuật web từ Addy Osmani: Tối ưu Core Web Vitals (LCP, INP, CLS), ngân sách bundle (JavaScript budget), progressive enhancement, lazy loading, import maps, tối ưu render loop và giảm thiểu chi phí xử lý JS trên trình duyệt.

8. **Understand Anything (Deep Codebase Archaeology):**
   * Thấu hiểu sâu sắc mọi codebase lạ: Khám phá kiến trúc ngược, truy vết luồng dữ liệu và symbol (`codebase-memory-mcp`), lập mô hình miền, trích xuất các invariants và giải thích bản chất hệ thống mà không hao phí token (`code-archaeologist`).

9. **Archify (Architecture Governance & ADRs):**
   * Quản trị kiến trúc hệ thống chuyên nghiệp: Tự động tác quyền Architecture Decision Records (ADR), dựng sơ đồ C4/Mermaid, phân định ranh giới module rõ ràng, phân tích ma trận trade-off trước khi thực thi.

10. **Impeccable (Craftsmanship, Strict Types & Zero Defects):**
    * Tiêu chuẩn code không tì vết: Strict typing tuyệt đối, validation phòng thủ tại các trust boundaries, bao quát toàn diện các edge-cases, tuân thủ Clean Code và đạt trạng thái zero linter/compiler warnings (`clean-code`, `lint-and-validate`).

---

## 3. Chi tiết triển khai

### 3.1. Các file cần tạo và sửa đổi

* **[NEW]** `modules/antigravity/files/mcp_config.json`: Cấu hình danh mục MCP servers chuẩn cho workstation.
* **[MODIFY]** [modules/antigravity/setup.sh](file:///home/loc/Workspaces/dotfiles/modules/antigravity/setup.sh): Tự động liên kết MCP config vào Antigravity IDE và Gemini CLI (`~/.gemini/antigravity-cli/mcp_config.json`).
* **[NEW]** `modules/shell/files/bin/rtk`: Utility script lọc và nén output lệnh terminal trước khi nạp vào context window (RTK Ultra).
* **[MODIFY]** [modules/shell/files/.zshrc](file:///home/loc/Workspaces/dotfiles/modules/shell/files/.zshrc): Bổ sung alias và helper cho RTK Ultra và AI workflows.
* **[NEW]** `.agents/rules/ponytail-yagni.md`: Định nghĩa quy chuẩn Senior YAGNI và đánh dấu cờ `ponytail:`.
* **[NEW]** `.agents/rules/caveman-mode.md`: Định nghĩa quy chuẩn giao tiếp cô đọng telegraphic.
* **[NEW]** `.agents/rules/ui-ux-pro-max.md`: Tiêu chuẩn bắt buộc `DESIGN.md` và anti-slop design.
* **[NEW]** `.agents/rules/web-performance.md`: Tiêu chuẩn Core Web Vitals và kiến trúc frontend theo Addy Osmani.
* **[NEW]** `.agents/rules/impeccable-code.md`: Tiêu chuẩn strict typing và zero linter/compiler warning.
* **[MODIFY]** [.agents/memory/MEMORY.md](file:///home/loc/Workspaces/dotfiles/.agents/memory/MEMORY.md): Ghi nhận conventions về bộ 10 kỹ năng cốt lõi và cấu hình MCP.

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
    },
    "agent-memory": {
      "command": "uvx",
      "args": ["agent-memory-mcp"],
      "env": {}
    }
  }
}
```

### 3.3. Ma trận Phối hợp 10 Kỹ Năng theo Giai đoạn Phát triển

| Giai đoạn | Kỹ năng AI Trọng tâm | Nhiệm vụ & Hành vi Chuẩn |
|---|---|---|
| **1. Khám phá & Định hình (Discovery & Planning)** | **Understand Anything** + **Archify** + **Superpowers** (`brainstorming`, `plan-writing`) | Bóc tách codebase hiện hữu, phát hiện invariants, phỏng vấn Socratic Gate làm rõ yêu cầu, lập ADR kiến trúc và chia nhỏ phase thực thi. |
| **2. Thiết kế Giao diện (Frontend & UX Design)** | **UI/UX Pro Max** + **Addy Osmani** | Thiết kế design tokens và bảng màu trong `DESIGN.md`, kiểm soát budget bundle, tối ưu hóa INP/LCP, loại bỏ mọi dấu vết "AI slop". |
| **3. Lập trình Cốt lõi (Core Implementation)** | **Ponytails** + **Impeccable** + **Superpowers** (`tdd-workflow`) | Thực hiện minimal working diff, xóa code thừa, strict typing, viết test tự chứng minh logic, gắn cờ `ponytail:` cho các điểm giản lược. |
| **4. Phân tích & Kiểm thử (Verification & Review)** | **Graphify** + **Superpowers** (`verify-changes`) + **RTK Ultra** | Tính toán blast radius qua AST graph, chạy lệnh build/test qua bộ lọc nén token `rtk`, chứng minh code chạy trước khi commit. |
| **5. Tương tác & Phản hồi (Pair Programming)** | **Caveman** + **AG Kit** (`memory-system`) | Giao tiếp telegraphic siêu cô đọng, tự động lưu trữ các quyết định kỹ thuật bền vững vào `.agents/memory/MEMORY.md`. |

---

## 4. Hướng dẫn sử dụng & Workflow

### 4.1. Quy trình Khởi động Tác vụ Phức tạp
```bash
# Agent tự động kích hoạt Socratic Gate, tra cứu memory và lập kế hoạch chi tiết
/orchestrator thực hiện tái cấu trúc module xác thực người dùng
```
* Agent áp dụng **Understand Anything** và **Graphify** để phân tích blast radius của module xác thực.
* Agent áp dụng **Archify** để xuất ADR kiến trúc ngắn gọn.
* Agent thực thi với tư duy **Ponytails** (ít code nhất, tận dụng thư viện sẵn có).

### 4.2. Quy trình Xây dựng UI Chuẩn UI/UX Pro Max & Addy Osmani
1. Trước khi viết bất kỳ file component nào:
   - Agent tạo file `DESIGN.md` chứa token màu, font, spacing và specs.
2. Kiểm tra hiệu năng tải trang:
   - Đảm bảo tuân thủ tiêu chuẩn Core Web Vitals (LCP < 2.5s, INP < 200ms, CLS < 0.1).
   - Kiểm tra zero layout shifts và lazy hydrate các thành phần tương tác nặng.

### 4.3. Tiết kiệm Token với RTK Ultra Filter
* Bọc các lệnh terminal dài bằng `rtk`:
  ```bash
  rtk git diff
  rtk npm test
  rtk cargo test
  ```
* Output tự động lược bỏ log thành công thừa, chỉ giữ lại tóm tắt và stacktrace lỗi quan trọng.

### 4.4. Phong cách Phản hồi Caveman Mode
* Định dạng phản hồi chuẩn:
  ```markdown
  Lỗi null pointer tại `auth_service.ts:42`. Thiếu kiểm tra token hết hạn.
  Đã sửa: thêm guard clause.
  Bước tiếp: chạy `npm test` nghiệm thu.
  ```

---

## 5. Tiêu chuẩn kiểm thử & Nghiệm thu (Verification)

1. **Kiểm tra MCP Servers:**
   * Antigravity IDE kết nối thành công các server: `codegraph`, `codebase`, `agent-memory`.
2. **Kiểm tra RTK Ultra Filter:**
   * Lệnh `rtk` lọc nén thành công output dài, giảm 60-80% lượng token cần đưa vào LLM.
3. **Kiểm tra Quy tắc 10 Kỹ Năng:**
   * Mọi session làm việc mới đều tự động nạp các quy tắc tại `.agents/rules/` và phản hồi đúng theo giao thức Caveman.
   * Mã nguồn sinh ra đạt tiêu chuẩn Ponytail (minimal diff, không boilerplate dư thừa) và Impeccable (strict types, zero lint errors).
   * Mọi UI mới đều có `DESIGN.md` đi kèm và được kiểm toán theo UI/UX Pro Max + Addy Osmani standards.
