#!/usr/bin/env bash

set -euo pipefail

info() {
    echo
    echo "==> $1"
}

success() {
    echo "✓ $1"
}

warn() {
    echo "! $1"
}

error() {
    echo "✗ $1" >&2
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NOCTALIA_CONFIG="$REPO_ROOT/resources/noctalia/config.toml"
NIRI_CONFIG="$REPO_ROOT/resources/niri/config.kdl"

if ! command -v noctalia >/dev/null 2>&1; then
    error "Lệnh 'noctalia' không tìm thấy trên hệ thống!"
fi

info "Đang đồng bộ cấu hình Noctalia (GUI -> Dotfiles)..."

# 1. Xuất cấu hình đã hợp nhất (gồm các thay đổi trên GUI) ra file tạm
TEMP_CONFIG="$(mktemp --suffix=.toml)"
trap 'rm -f "$TEMP_CONFIG"' EXIT

noctalia config export merged > "$TEMP_CONFIG"

# 2. Kiểm tra tính hợp lệ của cấu hình vừa xuất
if ! noctalia config validate "$TEMP_CONFIG" >/dev/null 2>&1; then
    error "Cấu hình Noctalia vừa xuất không hợp lệ! Đã hủy đồng bộ."
fi

# Keep user-specific paths out of the tracked configuration.
sed -i "s|$HOME|~|g" "$TEMP_CONFIG"

# 3. Ghi vào resources/noctalia/config.toml
cp "$TEMP_CONFIG" "$NOCTALIA_CONFIG"
success "Đã cập nhật: resources/noctalia/config.toml"

# 4. Áp dụng template (sinh màu cho Niri & các app khác)
info "Đang cập nhật templates màu sắc theo theme hiện tại..."
if noctalia msg templates-apply >/dev/null 2>&1; then
    success "Đã áp dụng templates thành công (noctalia.kdl đã được cập nhật)!"
else
    warn "Không thể gửi lệnh 'templates-apply' tới Noctalia (có thể daemon Noctalia chưa chạy)."
fi

# 5. Cập nhật palette cho Starship nếu có file palette sinh từ Noctalia
STARSHIP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/starship-palette.toml"
STARSHIP_CONFIG="$REPO_ROOT/resources/starship/starship.toml"
if [ -f "$STARSHIP_CACHE" ] && [ -f "$STARSHIP_CONFIG" ]; then
    if python3 -c "
import sys
cache_file, conf_file = sys.argv[1], sys.argv[2]
with open(cache_file) as f:
    palette = f.read().strip()
with open(conf_file) as f:
    content = f.read()
start = '# >>> NOCTALIA STARSHIP PALETTE >>>'
end = '# <<< NOCTALIA STARSHIP PALETTE <<<'
if start in content and end in content:
    pre = content.split(start)[0]
    post = content.split(end)[1]
    with open(conf_file, 'w') as f:
        f.write(f'{pre}{start}\n{palette}\n{end}{post}')
" "$STARSHIP_CACHE" "$STARSHIP_CONFIG" 2>/dev/null; then
        success "Đã đồng bộ palette Starship (resources/starship/starship.toml)!"
    fi
fi

# 6. Kiểm tra tính hợp lệ của cấu hình Niri
if command -v niri >/dev/null 2>&1; then
    if niri validate -c "$NIRI_CONFIG" >/dev/null 2>&1; then
        success "Cấu hình Niri hợp lệ!"
    else
        warn "Cấu hình Niri có cảnh báo hoặc lỗi. Hãy kiểm tra lại: $NIRI_CONFIG"
    fi
fi

info "Tóm tắt các thay đổi trong dotfiles:"
git -C "$REPO_ROOT" status --short "$REPO_ROOT/resources/noctalia" "$REPO_ROOT/resources/niri" "$REPO_ROOT/resources/kitty" "$REPO_ROOT/resources/starship" "$REPO_ROOT/resources/nvim" || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.

echo
success "Đồng bộ Noctalia hoàn tất! Bạn có thể git commit các thay đổi này."
