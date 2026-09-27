# 🤖 Hạ Tầng AI & Agent Skills (9Router & Skills Ecosystem)

Tài liệu này mô tả hạ tầng phục vụ các công cụ lập trình AI (Antigravity, Gemini CLI, Claude Code, OpenAI Codex) bao gồm MITM proxy 9Router, chứng chỉ CA và kho 80+ kỹ năng AI agent.

---

## 1. 9Router MITM Gateway

- **Vai trò:** Hoạt động như một proxy cục bộ trung gian (cổng `20128`), chuyển hướng các yêu cầu API từ Google Cloud Code, Gemini và Antigravity về gateway nội bộ mà không làm gián đoạn IDE.
- **Cấu hình DNS Loopback (`/etc/hosts`):**
  ```text
  127.0.0.1 daily-cloudcode-pa.googleapis.com
  127.0.0.1 cloudcode-pa.googleapis.com
  ```
- **Chứng chỉ bảo mật (Root CA):**
  - File chứng chỉ công khai: `9router-rootCA.crt`
  - Được nạp trực tiếp vào kho chứng chỉ hệ thống của Arch Linux để tránh lỗi xác thực SSL:
    ```bash
    sudo trust anchor /duong-dan/9router-rootCA.crt
    sudo update-ca-trust
    ```
- **Dịch vụ chạy ngầm:** Được quản lý tự động qua systemd user service `9router.service`.

---

## 2. Hệ Sinh Thái AI Agent Skills (80+ Curated Skills)

Hệ thống quản lý hơn 80 kỹ năng chuyên môn hóa cho các AI Coding Agents, được phân loại theo từng lĩnh vực phần mềm cụ thể.

### A. Cấu Trúc Quản Lý
- **Vị trí lưu trữ:** `modules/ai/skills/`
- **Các file registry & metadata:**
  - `_registry.json`: Bảng chỉ mục toàn bộ kỹ năng.
  - `_agents.json`: Danh sách các agent hỗ trợ (Antigravity, Claude Code, Codex, Gemini).
  - `_profiles.json`: Phân nhóm kỹ năng theo vai trò công việc.
- **Script điều phối:** `scripts/ai-skills.sh` (được alias thành `ai-skills` hoặc `add-skills`).

### B. Các Nhóm Kỹ Năng Tiêu Biểu:
- **Kiến Trúc & Thiết Kế:** `architecture-designer`, `domain-driven-design`, `microservices-decomposition`, `api-contract-designer`, `event-driven-architect`.
- **An Ninh & Bảo Mật:** `api-security-auditor`, `security-guardrails`, `prompt-injection-defense`, `cicd-security-hardening`, `vps-hardening`.
- **Chất Lượng & Kiểm Thử:** `qa-test-flow-engineer`, `unit-test-craftsman`, `eval-harness-designer`, `test-strategist`.
- **Frontend & UI/UX:** `tailwind-shadcn`, `nextjs-app-router`, `tanstack-query-state`, `pixel-perfect-ui`, `ui-styling`.
- **Backend & Cơ Sở Dữ Liệu:** `nestjs-cqrs-microservices`, `fastapi`, `golang`, `rust`, `postgresql`, `database-query-optimizer`, `bullmq`, `redis`.
- **DevOps & Cloud:** `docker-multiarch-builder`, `kubernetes`, `helm-chart-architect`, `gitops-terraform`, `aws-cloud-architect`, `gcp-cloud-architect`.

---

## 3. Lệnh Vận Hành

```bash
# Quản lý 9Router
9router start
9router status

# Xem danh sách các AI skills đang có
ai-skills list

# Đồng bộ skills vào agent mong muốn
ai-skills sync
```
