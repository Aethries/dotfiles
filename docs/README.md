# Project Documentation & Index

Tài liệu trong thư mục này đóng vai trò làm **mục lục tổng quan và chỉ mục định hướng** cho toàn bộ dự án dotfiles. Thư mục này hiện tại **không chứa thông tin triển khai chi tiết** của từng feature riêng lẻ.

Thông tin chi tiết về từng tính năng cụ thể được quản lý tại các tài liệu hướng dẫn trong thư mục này và mã nguồn cấu hình tương ứng trong `modules/`, `resources/`.

---

## Mục lục cơ bản (Documentation Index)

| STT | Mục / Tài liệu | Phạm vi quản lý | Trạng thái | Ghi chú |
| :---: | :--- | :--- | :---: | :--- |
| **01** | [`architecture.md`](./architecture.md) | Tổng quan kiến trúc, ranh giới đồng bộ & QA gates | Hoàn thành | Chuẩn kiến trúc cốt lõi |
| **02** | [`hardware-spec.md`](./hardware-spec.md) | Hướng dẫn cấu hình phần cứng nội bộ `.machine/` | Hoàn thành | Cách ly phần cứng |
| **03** | [`zellij-session-workflow.md`](./zellij-session-workflow.md) | Quy trình tạo, attach, restore và chọn layout Zellij | Hoàn thành | Session mới không ép layout; layout là opt-in |
| **04** | [`keymap-architecture.md`](./keymap-architecture.md) | Kiến trúc phím tắt Vim-style modal toàn hệ thống (Kanata, Niri, Zellij, Neovim) | Hoàn thành | Chuẩn điều hướng modal (Issue #25) |
| **05** | [`vault-security.md`](./vault-security.md) | Cơ chế mã hóa Age và quy trình sao lưu Secrets | Hoàn thành | Bảo mật & Secrets |
| **06** | `theme-specification.md` | Quy chuẩn bảng màu Noctalia và tích hợp Matugen | Placeholder | Dự thảo |
| **07** | `ergonomic-kanata.md` | Hướng dẫn cấu hình chi tiết và layout Kanata | Placeholder | Đang lên kế hoạch |
| **08** | [`github-cli-workflow.md`](./github-cli-workflow.md) | Alias GitHub CLI, issue/PR workflow và kiểm chứng cấu hình | Hoàn thành | Single source of truth tại `resources/gh/config.yml` |
