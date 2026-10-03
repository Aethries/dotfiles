---
type: user
created: 2026-07-18
updated: 2026-07-18
---

# User Preferences

- **Keyboard & Caret Ergonomics**: Ưu tiên repeat delay thấp (khoảng 180ms) và repeat rate cao (50Hz) để nhận caret nhanh và điều hướng mượt mà.
- **Display & Resolution Scaling**: Màn hình 1080p chạy scale `1.0` native (sắc nét 1:1, không mờ pixel) và tần số quét `120Hz` (`mode = 1920x1080@120`) trên cổng `HDMI-A-1`.
- **AI Agent Workflow**: Ưu tiên phong cách tối giản YAGNI (Ponytail), giao tiếp telegraphic ngắn gọn (Caveman), lọc nhiễu terminal (RTK Ultra), và tra cứu AST qua CodeGraph/Codebase MCP.
- **Git Restrictions**: Tuyệt đối KHÔNG tự ý chạy `git commit` hoặc `git push` nếu không có lệnh rõ ràng trong ĐÚNG message đó (cho phép ở message trước không có giá trị cho message sau). Chỉ sửa file và hiển thị diff để user kiểm tra/preview.
- **Không Silent Change**: Mọi thay đổi cấu hình/cài đặt phải được định nghĩa trong repo và sync được sang máy khác. Không âm thầm cài thư viện/gói ngầm ngoài hệ thống mà không khai báo vào module dotfiles.
- **Tuân thủ Conventions**: Mọi script, cấu trúc thư mục, đặt tên phải tuân thủ nghiêm ngặt chuẩn kiến trúc hiện có của repo dotfiles.
- **Clean Code & Dọn dẹp triệt để**: Không giữ lại rác. Nếu cài package hoặc viết code thử nghiệm không hoạt động hoặc đổi phương án, phải gỡ bỏ hoàn toàn (100%) các package và code thừa không liên quan.
