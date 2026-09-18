# Feature 10: AI Assistant

## 0. Mục tiêu cuối cùng

Hoàn thiện toàn bộ Feature 10 bao gồm:

- #16 Replace 9router with OmniRoute.
- #17 Reproducible OmniRoute bootstrap + NixOS integration.
- #18 Unified installer/sync layer cho AI tooling.
- #19 RTK integration.
- #20 Caveman integration.
- #21 CodeGraph + persistent codebase memory.
- #22 Bifrost integration.
- #23 Shared Skills / prompts / MCP / agent config.
- #24 Doctor, smoke test, migration test, fresh-machine test.

Kết quả cuối cùng phải đạt trạng thái:

```text
git clone repo
cd dotfiles
./scripts/bootstrap.sh
```

Sau khi lệnh trên thành công:

```text
NixOS packages ready
        │
        ├── OmniRoute installed
        │      └── omniroute.service enabled + running
        │
        ├── RTK installed
        ├── CodeGraph installed
        ├── Caveman integration synchronized
        ├── Shared Skills / MCP synchronized
        └── Optional Bifrost prepared

Codex ────────┐
Gemini ───────┤
Antigravity ──┼──> OmniRoute :20128 ───> Provider(s)
Future agent ─┘
```

Không được yêu cầu người dùng chạy thêm một script bí mật, copy binary thủ công hoặc sửa config ngoài repo để đạt trạng thái này.

---

# 1. Các nguyên tắc bắt buộc

Những nguyên tắc dưới đây là **hard constraints**, agent không được tự ý thay đổi.

### 1.1 Repo là source of truth

Mọi thứ quyết định hành vi hệ thống phải nằm trong Git:

- version tool;
- checksum;
- systemd units;
- config template;
- MCP definition;
- Skills;
- prompts/instructions;
- scripts;
- migration logic;
- health checks;
- tests;
- documentation.

Các thư mục runtime như cache, database, token và session được phép nằm ngoài Git, nhưng đường dẫn và lifecycle của chúng phải được khai báo trong repo.

### 1.2 Không sửa binary/package sau khi cài

Tuyệt đối không được có lại kiểu:

```bash
sed -i ... node_modules/...
```

hoặc patch trực tiếp binary/package đã cài.

Nếu upstream có bug:

1. pin version upstream đã fix;
2. hoặc patch declaratively trong Nix derivation;
3. hoặc chưa triển khai phần đó và fail với thông báo rõ ràng.

Không được sửa package sau khi cài.

### 1.3 Không dùng floating dependency

Cấm:

```text
latest
main
master
nightly
next
npm install -g package@latest
curl ... | sh
curl ... | bash
```

Mọi dependency bên ngoài phải có ít nhất:

```text
name
version/tag
source
revision nếu cần
sha256
installation strategy
```

OmniRoute phải pin một release ổn định. Baseline hiện tại của plan là `3.8.50`, không tự động upgrade trong quá trình bootstrap.

Tương tự baseline:

```text
OmniRoute  3.8.50
RTK        0.48.0
Caveman    2.7.0
CodeGraph  0.20.1
Bifrost    2.2.0
```

Versions sau này chỉ thay đổi bằng commit rõ ràng trong repo.

### 1.4 Không tạo unmanaged script ngoài repo

Không được generate script executable vào:

```text
~/.local/share/...
~/.config/...
/tmp/...
/usr/local/bin/...
```

Các command tiện ích tại `~/.local/bin` chỉ được là symlink trỏ ngược về:

```text
$REPO_ROOT/scripts/*
```

Binary third-party được quản lý bởi Nix hoặc một installer declarative đã được pin.

### 1.5 Không silent change

Các thao tác bên ngoài repo được chia thành hai nhóm.

**Được phép tự động nếu đã được định nghĩa rõ trong bootstrap:**

```text
tạo symlink config repo-owned
systemctl --user daemon-reload
systemctl --user enable --now omniroute.service
tạo runtime/cache directory
NixOS rebuild
```

**Không được tự động:**

```text
xóa config user hiện có
move config user sang backup
sửa /etc/hosts
sửa /usr/bin
thêm certificate vào system trust
loginctl enable-linger
xóa ~/.9router
xóa certificate cũ
xóa credential
ghi đè file user-owned
```

Những thao tác nhóm hai phải:

```text
./scripts/ai.sh ... --dry-run
```

hiển thị chính xác thay đổi trước, sau đó mới được thực thi qua option explicit.

### 1.6 Secrets tuyệt đối không vào Git

Repo chỉ chứa:

```text
secret schema
example
variable name
documentation
```

Không chứa:

```text
API key
OAuth token
cookie
refresh token
session
provider credential
private key
```

Tiếp tục sử dụng:

```text
secrets/
secrets.vault
scripts/vault.sh
```

theo convention hiện có.

### 1.7 Comment tiếng Việt

Các logic khó hiểu phải có comment tiếng Việt, đặc biệt:

- migration;
- merge config;
- secret handling;
- filesystem safety;
- symlink conflict;
- systemd lifecycle;
- hash/checksum verification;
- CodeGraph indexing exclusions;
- rollback;
- provider routing;
- compatibility workaround.

Không cần comment cho những dòng hiển nhiên như:

```bash
mkdir -p "$dir"
```

nhưng agent không được đưa thêm các đoạn logic phức tạp mà chỉ comment bằng tiếng Anh.

---

# 2. Kiến trúc đích

## 2.1 OmniRoute là gateway duy nhất phía client

Canonical endpoint:

```text
http://127.0.0.1:20128
http://127.0.0.1:20128/v1
```

OmniRoute upstream sử dụng port 20128 theo quickstart chính thức.

Tất cả:

```text
Codex
Gemini CLI
Antigravity
future terminal agents
```

phải nhìn thấy cùng một gateway.

Không cấu hình:

```text
Codex -> Bifrost
Gemini -> OmniRoute
Antigravity -> provider trực tiếp
```

vì như vậy workstation không còn một source of truth.

## 2.2 Không dùng `omniroute configure ...` làm source of truth

OmniRoute có command để ghi config Codex/Gemini trực tiếp.

Nhưng **bootstrap của repo không được phụ thuộc vào command này để mutate config user**.

Thay vào đó:

```text
resources/ai/
        ↓
scripts/ai.sh generate
        ↓
repo-owned generated configuration
        ↓
symlink
        ↓
Codex / Gemini / Antigravity
```

`omniroute configure --dry-run` chỉ được dùng trong debugging/compatibility test nếu cần.

## 2.3 Bifrost không được trở thành router thứ hai mặc định

Vai trò:

```text
CLIENT
  │
  ▼
OmniRoute
  │
  ├── direct providers
  │
  └── optional Bifrost backend
```

Bifrost mặc định:

```text
enabled = false
```

Không client nào trực tiếp phụ thuộc Bifrost.

Chỉ khi Bifrost được bật rõ ràng:

```bash
./scripts/ai.sh bifrost enable
```

thì mới start Bifrost và thêm nó như một upstream được quản lý.

Nếu implementation không xác minh được cách kết nối Bifrost vào OmniRoute tại version đã pin:

```text
FAIL CLOSED
```

Không tự đoán API/config.

Issue #22 chỉ được close khi boundary này được document và test.

---

# 3. Repo layout mới

Agent phải tạo cấu trúc gần như sau:

```text
resources/
└── ai/
    ├── README.md
    ├── manifest.json
    ├── schema/
    │   └── manifest.schema.json
    │
    ├── omniroute/
    │   ├── config.template.json
    │   └── README.md
    │
    ├── bifrost/
    │   ├── config.template.json
    │   └── README.md
    │
    ├── codegraph/
    │   ├── excludes.txt
    │   └── README.md
    │
    ├── shared/
    │   ├── prompts/
    │   ├── skills/
    │   ├── instructions/
    │   └── mcp/
    │       └── servers.json
    │
    ├── clients/
    │   ├── codex/
    │   ├── gemini/
    │   └── antigravity/
    │
    └── generated/
        ├── codex/
        ├── gemini/
        └── antigravity/

resources/systemd/user/
├── omniroute.service
└── bifrost.service            # nếu cần, disabled mặc định

pkgs/
├── omniroute.nix
├── rtk.nix
├── codegraph.nix
└── ...                        # chỉ thêm package thật sự cần thiết

scripts/
├── ai.sh
├── init-omniroute.sh           # compatibility/thin wrapper
└── sync-ai.sh                  # thin wrapper nếu cần

tests/ai/
├── manifest_test.sh
├── sync_test.sh
├── security_test.sh
├── service_test.sh
├── migration_test.sh
├── codegraph_test.sh
├── smoke_test.sh
└── fixtures/

docs/
├── ai-stack.md
└── ai-migration-9router.md
```

Không tạo thêm năm script bootstrap riêng cho năm tool.

Entry point duy nhất:

```bash
./scripts/ai.sh
```

và fresh-machine entry point vẫn là:

```bash
./scripts/bootstrap.sh
```

---

# 4. `resources/ai/manifest.json`

Manifest là metadata contract của AI stack.

Tối thiểu phải chứa:

```json
{
  "schemaVersion": 1,
  "gateway": "omniroute",
  "tools": {
    "omniroute": {
      "version": "3.8.50",
      "autostart": true,
      "port": 20128
    },
    "rtk": {
      "version": "0.48.0"
    },
    "caveman": {
      "version": "2.7.0"
    },
    "codegraph": {
      "version": "0.20.1"
    },
    "bifrost": {
      "version": "2.2.0",
      "enabled": false
    }
  }
}
```

Không dùng manifest để tự tải package tùy tiện.

Manifest dùng để:

- doctor biết version mong đợi;
- tests biết version mong đợi;
- documentation có một source of truth;
- installer kiểm tra drift;
- agent biết component nào enable/disable.

Package thực tế phải được pin declaratively trong Nix.

---

# 5. Quy tắc package

Thứ tự ưu tiên bắt buộc:

```text
1. Package đã tồn tại trong flake hiện tại
2. Local Nix derivation pinned version + checksum
3. Exact upstream release artifact + SHA256 qua Nix fetcher
4. Exact source revision build bởi Nix
```

Không được dùng:

```text
npm global latest
unversioned curl installer
IDE auto-download
binary được commit thẳng vào dotfiles
```

### OmniRoute

Ưu tiên package CLI/server, không lấy Electron AppImage 300 MB nếu feature chỉ cần gateway.

Nix package phải cho kết quả:

```bash
command -v omniroute
```

trỏ đến system/Nix profile ổn định.

Không được phụ thuộc:

```text
~/.local/bin/omniroute
```

mutable như 9router hiện tại.

### RTK

Phải xác minh đây là:

```text
rtk-ai/rtk
Rust Token Killer
```

không phải package khác cùng tên.

RTK 0.48.0 là baseline hiện tại.

Sau cài phải test:

```bash
rtk --version
rtk gain
```

`rtk gain` hoặc output nhận dạng tương đương phải chứng minh đúng Rust Token Killer.

### CodeGraph

Pin `codegraph-ai/CodeGraph` 0.20.1 hoặc version mới chỉ khi manifest được update có chủ ý.

Upstream publish binary và `.sha256`, vì vậy agent phải verify checksum trước khi Nix store chấp nhận artifact.

Không cho extension/IDE tự download CodeGraph binary lúc runtime.

### Caveman

Pin source/release v2.7.0.

Caveman không được tạo thêm một global proxy vì OmniRoute đã có compression engine dựa trên Caveman.

Trong Feature 10:

```text
Caveman standalone = shared agent skill/instruction integration
OmniRoute Caveman = request/context compression
```

Hai trách nhiệm này phải được document riêng.

### Bifrost

Pin HTTP transport version.

Nếu dùng container:

```text
image phải pin digest
```

không chỉ:

```text
maximhq/bifrost:latest
```

Nếu dùng Nix build thì pin source rev/hash.

Bifrost mặc định không auto-start.

---

# 6. `scripts/ai.sh`

Đây là control plane duy nhất cho AI stack.

Interface tối thiểu:

```text
./scripts/ai.sh bootstrap
./scripts/ai.sh sync
./scripts/ai.sh generate
./scripts/ai.sh start
./scripts/ai.sh stop
./scripts/ai.sh restart
./scripts/ai.sh status
./scripts/ai.sh doctor
./scripts/ai.sh test

./scripts/ai.sh migrate-9router --dry-run
./scripts/ai.sh migrate-9router --apply
./scripts/ai.sh cleanup-9router --dry-run
./scripts/ai.sh cleanup-9router --apply-system-cleanup

./scripts/ai.sh bifrost enable
./scripts/ai.sh bifrost disable
```

`bootstrap` phải theo đúng thứ tự:

```text
validate manifest
    ↓
verify package availability
    ↓
validate repo-owned config
    ↓
generate deterministic client config
    ↓
strict sync
    ↓
systemd daemon-reload
    ↓
enable + start OmniRoute
    ↓
health probe
    ↓
verify RTK
    ↓
verify CodeGraph
    ↓
verify Caveman skill
    ↓
check optional Bifrost state
    ↓
AI smoke tests
```

Nếu bước N fail:

```text
STOP
return non-zero
print remediation
```

Không tiếp tục rồi cuối cùng in `"success"`.

---

# 7. Strict sync, không phá config của user

Không dùng nguyên xi behavior hiện tại của `safe_link()` cho AI config, vì function hiện tại có thể tự move file user thành:

```text
.pre-dotfiles.<timestamp>
```

AI stack phải có function mới:

```text
strict_repo_link
```

Logic:

```text
destination không tồn tại
    -> tạo symlink

destination đã là symlink đúng
    -> no-op

destination là symlink sai
    -> fail

destination là regular file/directory
    -> fail
```

Output ví dụ:

```text
ERROR:
~/.codex/config.toml already exists and is not managed by dotfiles.

No files were modified.

Inspect:
  ~/.codex/config.toml

Then explicitly run:
  ./scripts/ai.sh sync --adopt codex
```

Chỉ `--adopt` mới được backup/migrate.

Không có silent takeover.

---

# 8. Phase 0: Baseline và safety tests

**Issue liên quan:** tất cả.

Chưa sửa behavior.

Trước tiên thêm tests mô tả những điều Feature 10 cấm.

### Test phải fail nếu tìm thấy trong AI code mới

```text
npm.*@latest
pnpm.*@latest
curl.*|.*sh
wget.*|.*sh
sed -i .*node_modules
rm /etc/hosts
tee .* /etc/hosts
/usr/bin/lsof
loginctl enable-linger
```

Allowlist migration documentation nếu cần.

### Inventory 9router

Agent phải tìm toàn repo:

```bash
rg -n -i '9router|\.9router|20128|cloudcode-pa|rootCA'
```

Tạo inventory vào:

```text
docs/ai-migration-9router.md
```

Phải ghi rõ từng reference:

```text
file
purpose
replacement
cleanup phase
whether external state exists
```

### Gate 0

Không được sang Phase 1 nếu chưa biết toàn bộ 9router touchpoint.

---

# 9. Phase 1: Unified AI foundation

**Issue:** #18.

Tạo:

```text
resources/ai/
manifest
schema
scripts/ai.sh
tests/ai/
docs/ai-stack.md
```

### `ai.sh bootstrap` giai đoạn này chưa được fake success

Nếu component chưa implement:

```text
NOT_IMPLEMENTED
```

và return non-zero nếu gọi feature tương ứng.

Không tạo stub trả `0`.

### State separation

Document rõ:

```text
Repo:
  declarative config

~/.config/...:
  repo-owned symlink hoặc local secret config

~/.local/state/...:
  generated runtime state

~/.cache/...:
  disposable cache

secrets/:
  plaintext local secret, gitignored

secrets.vault:
  encrypted local backup

workspace:
  CodeGraph index/memory state
```

### Gate 1

```bash
./scripts/check.sh
./tests/ai/manifest_test.sh
./tests/ai/security_test.sh
```

đều pass.

---

# 10. Phase 2: OmniRoute reproducible package

**Issue:** #17.

Tạo package OmniRoute.

### Không triển khai kiểu cũ

Không:

```bash
npm i -g omniroute@latest
```

OmniRoute upstream có global npm installation, nhưng dotfiles này phải bao bọc nó bằng dependency pin/reproducible package thay vì để mỗi máy tự lấy version mới nhất.

### Required checks

```bash
omniroute --version
```

phải bằng manifest.

Service không được start nếu version khác.

### Config

Repo chứa safe configuration.

Secret/provider auth vẫn ở local runtime data.

Không commit database hoặc credential của OmniRoute.

### Gate 2

Trên máy đã rebuild:

```bash
command -v omniroute
omniroute --version
```

đều thành công.

Chạy lại Nix build lần hai không sinh thêm unmanaged files.

---

# 11. Phase 3: OmniRoute systemd auto-start

**Issue:** #17.

Tạo:

```text
resources/systemd/user/omniroute.service
```

Mục tiêu:

```ini
[Unit]
Description=OmniRoute Local AI Gateway
After=default.target

[Service]
Type=simple
...
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
```

`ExecStart` phải trỏ tới executable declarative của Nix, không trỏ mutable `~/.local/bin`.

Exact command-line arguments phải được xác minh từ version OmniRoute đã pin.

Không đoán option.

### Bootstrap integration

Sau:

```bash
sudo nixos-rebuild switch ...
```

`bootstrap.sh` gọi:

```bash
"$REPO_ROOT/scripts/ai.sh" bootstrap
```

AI bootstrap phải:

```bash
systemctl --user daemon-reload
systemctl --user enable omniroute.service
systemctl --user start omniroute.service
```

hoặc atomic equivalent:

```bash
systemctl --user enable --now omniroute.service
```

Sau đó kiểm tra lại.

### Không bật linger mặc định

Không tự chạy:

```bash
sudo loginctl enable-linger
```

Autostart trong user session là đủ.

Nếu sau này muốn start trước login, đó là feature riêng và phải explicit.

### Service acceptance

```bash
systemctl --user is-enabled omniroute.service
systemctl --user is-active omniroute.service
```

phải đều success.

Sau:

```bash
systemctl --user restart omniroute.service
```

gateway phải quay lại healthy.

### Network safety

Test phải xác nhận gateway không vô tình expose ra toàn LAN.

Target:

```text
127.0.0.1:20128
```

Nếu version OmniRoute yêu cầu option cấu hình bind host, lấy option từ documentation/source version đã pin.

Không tự bịa flag.

### Gate 3

```text
enabled = yes
active = yes
port = listening
API = responsive
non-loopback unexpected listener = none
```

---

# 12. Phase 4: Migration 9router -> OmniRoute

**Issue:** #16.

Không delete 9router ngay.

Migration gồm ba stage.

## Stage A: side-by-side preparation

OmniRoute được package/config hoàn chỉnh nhưng chưa phá 9router.

Vì 9router và OmniRoute có thể tranh cùng port, parity test phải:

- dùng port test khác nếu OmniRoute version đã pin hỗ trợ;
- hoặc stop 9router có chủ ý trong test window;
- tuyệt đối không để hai process race trên cùng port.

## Stage B: parity

Kiểm thử:

```text
Codex -> OmniRoute
Gemini -> OmniRoute
Antigravity -> OmniRoute
/v1 chat completion
model listing
restart behavior
provider behavior
```

Chỉ sau parity mới cut over.

## Stage C: remove legacy repo integration

Remove:

```text
scripts/init-9router.sh
resources/systemd/user/9router.service

bootstrap:
  init-9router symlink
  9router-init symlink

doctor:
  init-9router checks
  9router service check

modules/services.nix:
  9router networking.extraHosts

modules/packages.nix:
  9router-only lsof comment/dependency nếu không dùng nơi khác
  nssTools nếu chỉ dùng cho 9router

vault.sh:
  9router restart lifecycle
  active 9router runtime handling
```

Sau cleanup:

```bash
rg -n -i 9router .
```

chỉ được match:

```text
migration documentation
legacy migration test fixture
explicit cleanup compatibility code
```

Không match normal runtime code.

### Không tự cleanup system state cũ

Ví dụ máy hiện tại có thể còn:

```text
~/.9router
/usr/local/share/ca-certificates/9router-root-ca.crt
NSS trust
/usr/bin/lsof symlink do old script tạo
```

`bootstrap` không được xóa chúng.

Thay vào đó:

```bash
./scripts/ai.sh cleanup-9router --dry-run
```

in:

```text
would remove ...
would unregister ...
would leave untouched ...
```

Sau đó user mới explicit:

```bash
./scripts/ai.sh cleanup-9router --apply-system-cleanup
```

### Gate 4

Fresh machine bootstrap không có bất cứ dependency nào vào 9router.

---

# 13. Phase 5: Shared Skills / prompts / MCP config

**Issue:** #23.

Tạo canonical source:

```text
resources/ai/shared/
```

Không để ba client có ba bản config được edit độc lập.

Luồng:

```text
shared source
     ↓
generator
     ↓
client-specific generated files
     ↓
strict symlink
```

### Generated marker

Mỗi format hỗ trợ comment phải có:

```text
AUTO-GENERATED FROM resources/ai/
DO NOT EDIT THIS FILE DIRECTLY
```

Nếu format JSON không cho comment, thêm metadata khi schema cho phép hoặc lưu checksum companion.

### Determinism

Hai lần:

```bash
./scripts/ai.sh generate
./scripts/ai.sh generate
```

phải tạo byte-for-byte cùng output.

### Existing Godot MCP

Không overwrite `resources/gemini/mcp_config.json` một cách mù quáng.

Generator phải merge canonical MCP list với Godot MCP đang tồn tại.

Acceptance:

```text
Godot MCP vẫn còn
CodeGraph MCP được thêm
không duplicate server
không mất existing arguments
```

### Config drift

`doctor` phải detect:

```text
source changed
generated config stale
symlink wrong
generated file manually modified
```

---

# 14. Phase 6: RTK integration

**Issue:** #19.

Cài canonical RTK bằng Nix.

### Không dùng global mutation

Không chạy tự động:

```bash
rtk init --global
```

nếu command đó sửa agent config ngoài source of truth.

Thay vào đó repo quản lý integration.

### RTK role

RTK standalone dùng cho:

```text
manual CLI
explicit agent integration
diagnostic/token savings inspection
```

Không buộc tất cả output đi qua standalone RTK vì OmniRoute đã có RTK-style compression trong pipeline của chính nó.

### Doctor checks

```text
binary exists
version correct
identity correct
rtk gain usable
```

### Test fixture

So sánh command:

```text
git status
git diff
test output
build output
```

qua RTK và đảm bảo:

- exit behavior đúng;
- không nuốt fatal error;
- có raw-output recovery nếu feature upstream hỗ trợ;
- không modify repository.

### Gate 6

RTK được provision trên fresh machine mà không có installer ngoài repo.

---

# 15. Phase 7: Caveman integration

**Issue:** #20.

Caveman standalone không làm router.

OmniRoute đã chứa Caveman-like engine trong compression pipeline.

Vì vậy standalone Caveman được dùng ở lớp:

```text
shared Skill / agent instruction
```

### Integration

Pin release.

Expose Caveman skill qua canonical:

```text
resources/ai/shared/skills/
```

Sau đó generator phân phối đến client hỗ trợ.

Không cho upstream installer tự ghi:

```text
~/.codex
~/.gemini
~/.claude
...
```

### Test

Doctor phải xác nhận:

```text
expected Caveman version/source pin
skill target exists
generated client integration current
no unmanaged Caveman installation required
```

### Gate 7

Fresh machine có skill/instruction giống nhau giữa supported agents.

---

# 16. Phase 8: CodeGraph + persistent memory

**Issue:** #21.

Đây là phần quan trọng để agent rẻ hơn vẫn hiểu codebase.

CodeGraph 0.20.1 publish platform binaries cùng SHA256.

Binary phải được Nix verify.

### Không auto-download

Disable/avoid mọi IDE behavior tải CodeGraph binary runtime.

Binary path phải do dotfiles cung cấp.

### MCP

Canonical MCP config khai báo CodeGraph.

Default profile phải ưu tiên bộ tool nhỏ thay vì expose toàn bộ surface nếu upstream hỗ trợ profile.

Lý do:

```text
fewer tool schemas
smaller system prompt
less agent confusion
lower token consumption
```

### Workspace safety

CodeGraph không bao giờ tự index:

```text
$HOME
/
~/Downloads
~/Documents
```

Chỉ index:

```text
explicit workspace
hoặc current git root
```

### Exclusions

`resources/ai/codegraph/excludes.txt` phải gồm ít nhất:

```text
.git
node_modules
.nix*
.env
.env.*
secrets
*.key
*.pem
.ssh
.gnupg
.aws
.kube
docker credentials
build artifacts
vendor cache
```

Nếu CodeGraph có native ignore mechanism thì generate đúng format đó.

### Persistent memory

Ưu tiên memory layer built into CodeGraph thay vì thêm một memory daemon khác nếu acceptance criteria đã đạt.

Memory phải:

```text
project scoped
persistent
invalidatable
queryable
not committed by default
```

### Commands

`ai.sh` cần abstraction:

```bash
./scripts/ai.sh codegraph index .
./scripts/ai.sh codegraph reindex .
./scripts/ai.sh codegraph status .
./scripts/ai.sh codegraph clear .
```

`clear` phải yêu cầu explicit confirmation hoặc option.

### Staleness

Store metadata tối thiểu:

```text
workspace realpath
git HEAD lúc index
timestamp
CodeGraph version
config hash
```

`doctor` cảnh báo nếu:

```text
HEAD thay đổi đáng kể
config hash khác
CodeGraph version khác
database missing/corrupted
```

Không nhất thiết reindex mỗi commit nếu upstream tự incremental update, nhưng doctor phải biết trạng thái.

### Tests

Bằng fixture repository nhỏ:

```text
index
search symbol
find reference
store memory
restart MCP
read memory
change fixture
detect/update index
```

### Gate 8

Agent mới mở project có thể lấy structural context + memory mà không copy/paste thủ công.

---

# 17. Phase 9: Bifrost

**Issue:** #22.

Bifrost là optional component.

Manifest:

```json
"bifrost": {
  "enabled": false
}
```

### Không chạy mặc định

Fresh machine:

```text
Bifrost installed/preparable
Bifrost service disabled
OmniRoute healthy
```

### Enable workflow

```bash
./scripts/ai.sh bifrost enable
```

phải:

1. validate config;
2. validate required secrets;
3. provision/start pinned runtime;
4. health check Bifrost;
5. configure OmniRoute upstream only through repo-owned config;
6. restart/reload OmniRoute nếu thật sự cần;
7. execute routing smoke test.

Nếu bước 5 không có documented path tại version đã pin:

```text
abort
do not modify OmniRoute
```

### Port

Bifrost không dùng port 20128.

Port phải được khai báo trong manifest/config.

### Disable

```bash
./scripts/ai.sh bifrost disable
```

phải:

- stop optional service;
- remove it khỏi generated OmniRoute config;
- giữ credential/data nguyên vẹn;
- restart/reload OmniRoute;
- prove direct OmniRoute routing works.

### Gate 9

Bifrost không bao giờ là dependency để OmniRoute khởi động.

---

# 18. Phase 10: Vault/secrets migration

Cập nhật `vault.sh`.

### Remove active 9router lifecycle

Loại bỏ:

```text
RESTORE_RESTART_9ROUTER
9router process stop/start
active .9router dependency
```

### Add OmniRoute runtime state

Chỉ backup những phần thực sự chứa:

```text
credential
provider authentication
persistent user settings
```

Không backup:

```text
logs
cache
PID
temporary files
model cache có thể rebuild
```

Exact paths phải lấy từ OmniRoute pinned version tại implementation time.

Agent phải inspect upstream source/docs, không đoán.

### Service restore

Nếu OmniRoute đang active trước vault restore:

```text
record active state
stop service
restore credential data
fix permissions
start service lại
health probe
```

Nếu trước restore service không active:

```text
không được tự bật nó chỉ vì vault restore
```

### File permissions

Secret files:

```text
0600
```

Secret directories:

```text
0700
```

### Logging

Không được log:

```text
API key
token
cookie
Authorization header
secret env contents
```

---

# 19. Phase 11: Doctor

**Issue:** #24.

Thêm section:

```text
AI Assistant Stack
```

Output mẫu:

```text
==> AI Assistant Stack

[✓] AI manifest schema valid
[✓] OmniRoute 3.8.50
[✓] OmniRoute service enabled
[✓] OmniRoute service active
[✓] OmniRoute API listening on loopback :20128
[✓] OmniRoute API health check
[✓] RTK 0.48.0
[✓] RTK identity verified
[✓] Caveman integration 2.7.0
[✓] CodeGraph 0.20.1
[✓] CodeGraph MCP configuration current
[✓] CodeGraph secret exclusions configured
[✓] Shared AI configuration synchronized
[✓] Codex config synchronized
[✓] Gemini config synchronized
[✓] Antigravity config synchronized
[-] Bifrost disabled by configuration
[✓] No active 9router integration
```

### Doctor rules

`doctor`:

- không modify;
- không restart;
- không install;
- không repair;
- không print secrets.

Doctor chỉ inspect.

Mỗi failure phải có remediation, ví dụ:

```text
[✗] OmniRoute service inactive
    Fix:
      ./scripts/ai.sh restart

[✗] Gemini config stale
    Fix:
      ./scripts/ai.sh sync

[✗] CodeGraph binary version mismatch
    Expected: 0.20.1
    Found:    0.19.0
    Fix:
      ./scripts/build.sh switch
```

---

# 20. Phase 12: Static CI tests

Mở rộng `scripts/check.sh`.

Thứ tự:

```text
bash syntax
shellcheck
AI security policy tests
JSON/schema validation
generated config determinism
Nix formatting
nix flake check
systemd verify
unit tests
existing vault tests
existing zellij tests
AI tests
```

### Security assertions

Test fail nếu AI implementation có:

```text
floating release
curl pipe shell
direct /etc mutation
direct /usr mutation
post-install source patch
secret committed
unverified downloaded executable
unexpected sudo
```

### Secret scan

Tối thiểu check patterns:

```text
sk-...
Bearer ...
API_KEY=<non-placeholder>
private key headers
OAuth refresh token shapes
```

Tốt hơn thêm dedicated secret scanner nếu có package Nix phù hợp, nhưng không đưa dependency mới chỉ để trang trí.

---

# 21. Phase 13: Unit tests

Tests không cần provider thật.

Phải test:

### Manifest

```text
valid schema accepted
unknown field behavior defined
floating version rejected
missing checksum rejected khi artifact cần checksum
invalid port rejected
multiple default gateways rejected
```

### Filesystem sync

```text
missing target -> link
correct link -> no-op
wrong link -> fail
existing normal file -> fail
--adopt -> explicit migration
second run -> no changes
```

### Config generation

```text
deterministic
Godot MCP preserved
CodeGraph inserted exactly once
same source -> same checksum
manual generated-file change detected
```

### Systemd wrapper

Mock `systemctl`.

Test:

```text
enable success
start success
start fail
health fail
already active
restart
```

Không cần thật sự start process trong unit test.

### Migration

Fixture giả lập:

```text
9router files exist
legacy systemd link
legacy config
```

Dry-run phải không thay đổi fixture.

Apply phải chỉ thay đổi allowlisted paths.

---

# 22. Phase 14: Integration smoke tests

Tạo:

```bash
./tests/ai/smoke_test.sh
```

Hoặc:

```bash
./scripts/ai.sh test --smoke
```

### OmniRoute

Test:

```text
process active
port active
HTTP responds
models/API responds
minimal chat request succeeds
```

OmniRoute hiện có zero-config `auto` behavior theo upstream, nên có thể dùng làm một smoke path khi version pin còn hỗ trợ nó.

Tuy nhiên live network test không thay thế deterministic test.

### CI/mock test

CI phải dùng local mock upstream khi có thể.

Mục tiêu:

```text
không tốn API credit
không phụ thuộc provider ngoài
deterministic
```

### Live acceptance test

Trên máy thật, chạy đúng một request nhỏ:

```text
prompt: "Reply exactly: OK"
temperature thấp nếu API hỗ trợ
max token rất nhỏ
```

Verify:

```text
HTTP success
response non-empty
routing qua OmniRoute
không fallback trực tiếp ngoài gateway
```

---

# 23. Phase 15: Client tests

## Codex

Verify config được quản lý bởi repo.

Verify endpoint là OmniRoute.

Run minimal connectivity test.

Không overwrite credential/history của Codex.

## Gemini

Existing:

```text
resources/gemini/mcp_config.json
```

phải tiếp tục giữ Godot MCP.

Verify CodeGraph MCP handshake.

Verify gateway config.

## Antigravity

Không phá:

```text
settings
keybindings
extension lock
Godot workflow
```

Existing extension synchronization tiếp tục hoạt động.

AI sync chỉ mở rộng, không rewrite unrelated editor config.

---

# 24. Phase 16: CodeGraph agent-quality test

Đây là test riêng cho yêu cầu “AI agent rẻ hơn vẫn làm được”.

Tạo một fixture repo có:

```text
src/
  user.ts
  user.service.ts
  user.controller.ts
tests/
README
```

Sau index, đưa một agent/context consumer các câu hỏi:

```text
Where is User created?
Which function calls createUser?
Which test covers createUser?
What convention is used for error handling?
```

Mục tiêu test infrastructure, không benchmark IQ model.

Agent phải có thể lấy:

```text
symbols
references
memory
project conventions
```

qua CodeGraph/MCP thay vì scan toàn repo mỗi lần.

Điều này giảm context required và giảm phần suy luận vô ích cho model nhỏ.

---

# 25. Phase 17: Fresh-machine test

Đây là gate quan trọng nhất.

Feature chưa hoàn thành nếu chỉ chạy trên máy development hiện tại.

## Test A: isolated HOME

Dùng temporary HOME.

Không được đọc nhầm config thật.

Verify:

```text
sync
generation
conflict handling
runtime directories
```

## Test B: Nix evaluation/build

```bash
nix flake check "path:$PWD" --no-build
```

và build package AI riêng nếu có thể.

## Test C: NixOS VM

Nên tạo NixOS VM test cho phần declarative:

```text
OmniRoute package installed
service unit present
service starts
port health
RTK binary exists
CodeGraph binary exists
```

Không cần desktop GUI.

## Test D: real clean-machine acceptance

Trên một NixOS machine mới:

```bash
git clone ...
cd dotfiles
./scripts/bootstrap.sh
```

Sau khi complete:

```bash
./scripts/doctor.sh
./scripts/ai.sh status
./scripts/ai.sh test --smoke
```

Tất cả required checks phải pass.

Sau đó chạy lần thứ hai:

```bash
./scripts/bootstrap.sh
```

Kết quả:

```text
không duplicate
không backup thêm file
không đổi generated config
không đổi Git working tree
không tạo service duplicate
không mất credential
OmniRoute vẫn active
```

Đây là idempotency acceptance test.

---

# 26. Bootstrap final contract

Cuối Feature 10, `bootstrap.sh` phải có luồng logic:

```text
environment validation
        ↓
machine config
        ↓
repo config links
        ↓
NixOS rebuild
        ↓
sync editor config
        ↓
AI bootstrap
        ↓
AI service start
        ↓
AI smoke/health check
        ↓
done
```

Không được in:

```text
Bootstrap completed
```

nếu `ai.sh bootstrap` fail.

---

# 27. 9router cleanup checklist

Trước khi close #16, agent phải search:

```bash
rg -n -i \
  '9router|\.9router|9router-init|init-9router|cloudcode-pa|9Router MITM' \
  .
```

Review từng match.

Normal runtime phải không còn:

```text
init-9router.sh
9router.service
9router package
9router npm install
9router certificate setup
9router DNS entry
9router doctor check
9router bootstrap aliases
9router vault restart behavior
```

Migration docs/test fixtures được phép giữ tên 9router.

---

# 28. Definition of Done từng issue

## #16

Done khi:

```text
9router không còn runtime dependency
OmniRoute là gateway canonical
client parity pass
legacy cleanup explicit
fresh machine không biết tới 9router
```

## #17

Done khi:

```text
OmniRoute pinned
reproducible
systemd auto-start
bootstrap starts service
doctor verifies service/API
second bootstrap idempotent
```

## #18

Done khi:

```text
có một AI manifest
một AI control script
một sync convention
không còn bespoke installer pattern
```

## #19

Done khi:

```text
canonical RTK installed
version/identity checked
doctor aware
fresh machine works
```

## #20

Done khi:

```text
Caveman pinned
shared skill integrated
no hidden installer
no duplicate proxy
```

## #21

Done khi:

```text
CodeGraph pinned
MCP works
persistent memory works
safe indexing
staleness detection
secret exclusion
```

## #22

Done khi:

```text
Bifrost role documented
disabled by default
explicit enable/disable
no competing client gateway
health checks
```

## #23

Done khi:

```text
single canonical shared config
Codex/Gemini/Antigravity generated from it
drift detectable
sync idempotent
```

## #24

Done khi:

```text
doctor
static checks
unit tests
integration smoke
migration tests
fresh-machine tests
all exist and pass
```

---

# 29. Commit sequence dành cho coding agent

Agent không được làm toàn bộ Feature 10 trong một commit khổng lồ.

Thứ tự commit:

```text
1. test(ai): add Feature 10 safety and manifest tests

2. feat(ai): add canonical AI stack manifest and control layer

3. feat(omniroute): add pinned reproducible OmniRoute package

4. feat(omniroute): add managed user service and autostart

5. feat(ai): add shared agent config and deterministic sync

6. feat(rtk): add reproducible RTK integration

7. feat(caveman): add shared Caveman skill integration

8. feat(codegraph): add graph and persistent memory integration

9. feat(bifrost): add optional backend integration

10. refactor(ai): migrate runtime from 9router to OmniRoute

11. test(ai): add full doctor and smoke coverage

12. docs(ai): finalize fresh-machine and migration documentation
```

Sau **mỗi commit**:

```bash
./scripts/check.sh
```

Sau commit liên quan AI:

```bash
./scripts/ai.sh doctor
```

nếu environment cho phép.

Không được tiếp tục phase tiếp theo khi test phase hiện tại fail.

---

# 30. Quy tắc cho agent khi gặp thông tin không chắc chắn

Agent phải tuân thủ:

```text
Không biết path config upstream?
-> đọc source/docs của exact pinned version.

Không biết CLI flag?
-> chạy --help hoặc đọc source exact pinned version.

Không biết secret location?
-> inspect exact version.
-> không đoán.

Không biết Bifrost có thể làm upstream cho OmniRoute?
-> không wire.
-> document blocker.
-> leave disabled.

Không biết một file user có thể overwrite không?
-> không overwrite.

Không biết command có destructive không?
-> implement --dry-run trước.

Không xác minh được checksum?
-> không execute artifact.
```

Không được “thử đại cho chạy”.

---

# 31. Required Vietnamese comments

Ví dụ logic migration nên có style:

```bash
# Không tự động xóa dữ liệu 9router cũ vì thư mục này có thể
# chứa credential hoặc session chưa được migrate. Cleanup chỉ
# được phép chạy khi người dùng truyền --apply-system-cleanup.
```

Config merge:

```bash
# File Gemini hiện đã chứa Godot MCP. Chúng ta merge theo server ID
# thay vì ghi đè toàn bộ để tránh làm mất cấu hình MCP hiện có.
```

Symlink:

```bash
# Không tự động move file cấu hình do người dùng sở hữu.
# Nếu destination không phải symlink của dotfiles thì dừng và
# yêu cầu người dùng chạy lại với --adopt.
```

CodeGraph:

```bash
# Chỉ cho phép index một Git workspace cụ thể. Không fallback về
# HOME vì thao tác đó có thể vô tình index SSH key hoặc secret.
```

Không cần comment những đoạn code quá hiển nhiên.

---

# 32. Final acceptance command set

Trước khi đánh dấu Feature 10 hoàn tất, phải chạy toàn bộ:

```bash
./scripts/check.sh

./scripts/ai.sh generate
git diff --exit-code

./scripts/ai.sh sync
./scripts/ai.sh sync

./scripts/ai.sh doctor

systemctl --user is-enabled omniroute.service
systemctl --user is-active omniroute.service

./scripts/ai.sh test
./scripts/ai.sh test --smoke

rg -n -i '9router|\.9router' .
```

Sau đó reboot/login test:

```bash
systemctl --user is-active omniroute.service
./scripts/ai.sh doctor
```

Cuối cùng test bootstrap lần hai:

```bash
./scripts/bootstrap.sh
git status --short
```

`git status` không được xuất hiện generated drift do bootstrap.

---

# 33. Feature 10 chỉ được đóng khi

Toàn bộ điều sau cùng đúng:

```text
[ ] #16 complete
[ ] #17 complete
[ ] #18 complete
[ ] #19 complete
[ ] #20 complete
[ ] #21 complete
[ ] #22 complete
[ ] #23 complete
[ ] #24 complete

[ ] OmniRoute starts automatically
[ ] OmniRoute survives restart/login
[ ] fresh machine needs only bootstrap.sh
[ ] second bootstrap is idempotent
[ ] no arbitrary binary patch
[ ] no floating version
[ ] no remote curl | sh installer
[ ] no silent external mutation
[ ] no secrets in Git
[ ] no direct /etc/hosts mutation
[ ] no direct /usr/bin mutation
[ ] all custom scripts live in repo
[ ] client config derives from repo
[ ] CodeGraph does not index secrets/home accidentally
[ ] doctor prints no credentials
[ ] 9router runtime dependency fully removed
[ ] Codex works through OmniRoute
[ ] Gemini works through OmniRoute
[ ] Antigravity works through OmniRoute
[ ] CodeGraph MCP works
[ ] persistent memory survives restart
[ ] RTK identity/version verified
[ ] Caveman integration verified
[ ] optional Bifrost does not affect default gateway
[ ] all complicated code contains Vietnamese explanatory comments
[ ] ./scripts/check.sh passes
[ ] full AI smoke test passes
```

Nếu bất kỳ checkbox nào chưa đạt thì milestone Feature 10 chưa được xem là hoàn thành.
