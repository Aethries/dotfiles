# Dotfiles `main` Final Code Review & Remediation Plan

> Repository: `Aethries/dotfiles`  
> Reviewed branch: `main`  
> Reviewed commit: `3c2d46eaf15579f09031437ab9ee74bc24d7b99d`  
> Review date: 2026-09-19  
> Scope: clean code, portable-vs-machine-local architecture, syntax/QA, fresh-machine bootstrap reliability, 9Router/OmniRoute requirements, reproducibility, and failure modes.

---

## 1. Project philosophy used for this review

This review uses the following rule as the architectural source of truth.

### Repository SHOULD sync

The repository should contain portable desired workstation state:

- Packages and developer tools.
- Niri, Noctalia, Kitty, Zellij, Neovim, shell, Starship, Fcitx configuration.
- Reusable scripts.
- Reproducible system services required by the workstation workflow.
- Docker, PipeWire, KDE Connect and similar portable workstation capabilities.
- 9Router and OmniRoute configuration required for those features to work.
- 9Router DNS host mappings required by MITM routing.
- 9Router public Root CA certificate.
- AI gateway ports, service templates, health checks and non-secret defaults.
- Editor extension lockfiles and checksums.
- Common locale/UI/application preferences that intentionally apply to every workstation.

### Repository MUST NOT sync machine identity/state

The repository must not force state that belongs only to one physical machine:

- Hostname.
- User account names.
- User passwords.
- Wi-Fi SSIDs/passwords/profiles.
- Generated `hardware-configuration.nix`.
- Disk layout and filesystem UUIDs.
- Swap size/layout.
- Bootloader selection when it depends on the target machine.
- GPU vendor/driver assumptions.
- Device-specific udev rules.
- Keyboard/device hardware quirks.
- Machine-specific kernel parameters.
- Machine-specific `system.stateVersion`.
- MAC addresses.
- Private keys.
- OmniRoute database and storage encryption key.
- Browser/application session state.

### Decision rule

```text
Does this setting describe this physical machine?
    |
    +-- YES --> .machine/ or another local ignored state
    |
    +-- NO --> Does a portable repo feature require it?
                  |
                  +-- YES --> tracked repository config
                  |
                  +-- NO --> keep it local / optional
```

---

# 2. Priority summary

| Priority | ID | Title | Main risk |
|---|---|---|---|
| P0 | P0-01 | Fresh installer loses `install_user` between functions | Installation can fail after disk formatting |
| P1 | P1-01 | Hardcoded `users.users.loc` in common module | User identity leaks across machines |
| P1 | P1-02 | Intel GPU configuration is globally imported | Wrong GPU assumptions on AMD/NVIDIA/VM machines |
| P1 | P1-03 | WEIKAV NUT75 and seatd workaround is globally imported | One machine's hardware quirk changes every machine |
| P1 | P1-04 | Global 32 GiB swap conflicts with installer-created swap | Fresh machine can receive unintended double swap |
| P1 | P1-05 | Bootloader policy is stored in common `base.nix` | New machine may use incompatible boot configuration |
| P1 | P1-06 | Machine-specific kernel parameters are globally synced | Hardware behavior and power policy leak across machines |
| P1 | P1-07 | `system.stateVersion` is common instead of machine-local | Future machines inherit another machine's lifecycle baseline |
| P1 | P1-08 | 9Router mutates `/etc/hosts` although Nix owns it | Declarative state is broken and rebuilds can drift |
| P1 | P1-09 | 9Router creates `/usr/bin/lsof` and may install via `nix profile` | Multiple owners for one dependency and filesystem drift |
| P1 | P1-10 | 9Router uses `9router@latest` | Non-reproducible and supply-chain/update risk |
| P1 | P1-11 | 9Router patches installed npm internals with `sed` | Fragile against upstream layout/version changes |
| P1 | P1-12 | Fresh-install/bootstrap path has no end-to-end integration test | Runtime orchestration bugs can pass all current checks |
| P2 | P2-01 | 9Router CA trust is managed by two mechanisms | Duplicate ownership and hard-to-debug trust state |
| P2 | P2-02 | `bootstrap.sh` has too many responsibilities | Difficult to reason about, test and safely retry |
| P2 | P2-03 | Bootstrap accepts `aarch64` while flake is x86_64-centric | False portability contract |
| P2 | P2-04 | Greeter derives primary user by taking first normal user | Wrong user can receive passwordless sync permission |
| P2 | P2-05 | `safe_link` does not validate source existence | Broken symlinks can be created silently |
| P2 | P2-06 | Bootstrap performs broad recursive ownership repairs | Can rewrite ownership unrelated to the exact operation |
| P2 | P2-07 | `build.sh` claims rollback but does not restore anything | Misleading recovery semantics |
| P2 | P2-08 | No explicit preflight stage before system mutation | Errors are discovered too late |
| P2 | P2-09 | Actual deployment path is legacy `nixos-rebuild -I`, not a flake target | Flake is not the authoritative deployment entrypoint |
| P2 | P2-10 | Secret archive policy and documentation are inconsistent | Users cannot tell what should be committed/synced |
| P2 | P2-11 | Main branch has no protection and repository has no tracked CI workflow | Local checks can be bypassed on `main` |
| P3 | P3-01 | `lsof` is duplicated in package list | Clean-code noise |
| P3 | P3-02 | Unused `pkgs` argument in `modules/services.nix` | Minor dead code |
| P3 | P3-03 | Common modules mix unrelated responsibilities | Future changes become harder to isolate |
| P3 | P3-04 | Comments/documentation contradict current implementation | Reviewers and agents can follow the wrong model |
| P3 | P3-05 | Some `|| true` paths suppress meaningful failures | Partial configuration may be reported as acceptable |
| P3 | P3-06 | `test-isolated.sh` validates editors more than system bootstrap | Test name/scope can create false confidence |

---

# 3. P0: must fix before using the fresh installer

## P0-01 — Fresh installer loses `install_user` between functions

### Description

`setup_config()` declares the selected user as a local shell variable:

```bash
local install_user
```

Later, `run_install()` reads:

```bash
local dotfiles_dir="/mnt/home/$install_user/dotfiles"
local machine_config="$dotfiles_dir/.machine/configuration.nix"
```

Because `install_user` only exists inside `setup_config()`, it is not available when `run_install()` executes.

The script uses:

```bash
set -euo pipefail
```

Therefore an unset variable is fatal.

### Why this is P0

The installer performs destructive operations before reaching this code:

1. Select disk.
2. Wipe signatures.
3. Create GPT.
4. Create partitions.
5. Format EFI/swap/root.
6. Mount root.
7. Clone dotfiles.
8. Generate machine config.
9. Enter `run_install()`.
10. Fail on unbound `install_user`.

This means a syntax-valid script can still fail after destructive disk work.

### Files

- `scripts/nixos-installer.sh`

### Required fix

Do not depend on implicit global state.

Preferred implementation:

```bash
setup_config() {
    ...
    INSTALL_USER="$selected_user"
}
```

is workable but still uses global mutable state.

A cleaner implementation is to pass values explicitly:

```bash
run_install() {
    local install_user="$1"
    local dotfiles_dir="/mnt/home/$install_user/dotfiles"
    ...
}

main() {
    ...
    setup_config
    run_install "$INSTALL_USER"
}
```

An even cleaner design is for `setup_config` to write required machine metadata into a well-defined state file or return it in a controlled manner.

### Acceptance criteria

- Running the installer with `set -u` never reads an unset `install_user`.
- `run_install` receives the user explicitly.
- A test verifies the complete function flow without formatting a real disk.
- The test reaches the `nixos-install` mock with the expected path:
  `"/mnt/home/<user>/dotfiles/.machine/configuration.nix"`.

### Required test

Add an installer orchestration test with mocked commands:

- `lsblk`
- `wipefs`
- `parted`
- `mkfs.fat`
- `mkfs.ext4`
- `mkswap`
- `swapon`
- `mount`
- `git clone`
- `nixos-generate-config`
- `nixos-install`

The test must assert that the selected username survives from configuration setup through installation execution.

---

# 4. P1: architecture and fresh-machine reliability blockers

## P1-01 — Hardcoded `users.users.loc` in a common module

### Description

`modules/services.nix` contains user-specific configuration:

```nix
users.users.loc.extraGroups = [
  "seat"
  "input"
  "video"
];
```

This violates the repository boundary because `loc` is machine/user identity, not portable workstation configuration.

### Failure mode

A target machine whose user is `alice`, `dev`, or another name still evaluates configuration containing `users.users.loc`.

This can:

- Create or mutate an unintended account.
- Cause module assumptions to diverge from the user generated by bootstrap.
- Make common modules depend on one person's username.

### Required fix

Remove all named normal users from tracked common modules.

Put user-specific group membership into generated `.machine/configuration.nix`:

```nix
users.users."${machineUser}" = {
  isNormalUser = true;
  extraGroups = [
    "wheel"
    "networkmanager"
    "input"
    "uinput"
    "docker"
    "seat"
    "video"
  ];
};
```

If group membership is required by a portable feature, expose the required group list as reusable data, but apply it to the machine-selected user only.

### Acceptance criteria

- `grep -R 'users\.users\.loc' modules resources scripts` returns nothing except explicit tests/docs.
- A machine can bootstrap with an arbitrary valid Linux username.
- No common Nix module contains a personal username.

---

## P1-02 — Intel GPU configuration is globally imported

### Description

`modules/desktop.nix` sets:

```nix
hardware.graphics.extraPackages = with pkgs; [
  intel-media-driver
  intel-vaapi-driver
  vpl-gpu-rt
];

environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
```

The comment itself says the block is Intel-specific, but `configuration.nix` imports it for every machine.

### Failure mode

On AMD, NVIDIA, VM, or a different Intel setup:

- Unnecessary Intel packages are installed.
- `LIBVA_DRIVER_NAME=iHD` can force the wrong VA-API driver.
- Hardware-specific behavior leaks from the original machine.

### Required fix

Split portable desktop configuration from hardware acceleration.

Recommended structure:

```text
modules/
  desktop.nix
  hardware/
    intel-graphics.nix
    weikav-nut75.nix

.machine/
  hardware-configuration.nix
  hardware-extra.nix
```

`modules/hardware/intel-graphics.nix` may remain tracked because it is reusable, but it MUST NOT be globally imported.

`.machine/hardware-extra.nix` chooses it:

```nix
{
  imports = [
    ../modules/hardware/intel-graphics.nix
  ];
}
```

### Acceptance criteria

- Common `desktop.nix` contains no Intel-specific driver selection.
- AMD/NVIDIA/VM machines can evaluate common configuration without Intel assumptions.
- Machine-local configuration controls which optional hardware module is imported.

---

## P1-03 — WEIKAV NUT75 and seatd workaround is globally imported

### Description

`modules/services.nix` contains a device-specific udev workaround for vendor/product IDs:

- `0c45:fef9`
- `0c45:880c`

It also changes seat management globally through `seatd` and `LIBSEAT_BACKEND=seatd`.

### Failure mode

Every target machine receives a workaround created for one keyboard and one hardware/`systemd-logind` issue.

That changes system behavior even when the target machine does not own the device.

### Required fix

Create:

```text
modules/hardware/weikav-nut75.nix
```

Move into it:

- `services.seatd`
- `LIBSEAT_BACKEND`
- WEIKAV udev rules
- Any related device-specific groups if they are exclusively needed for this workaround.

Do not import the module from common `configuration.nix`.

Import it only from `.machine/hardware-extra.nix` on machines that need it.

If `seatd` is independently required for Niri on all supported machines, separate that generic requirement from the WEIKAV-specific rule. Do not couple two different reasons in one block.

### Acceptance criteria

- No USB vendor/product IDs exist in globally imported modules.
- A machine without the keyboard does not enable the workaround merely by cloning the repo.
- Hardware feature modules are opt-in.

---

## P1-04 — Global 32 GiB swap conflicts with installer-created swap

### Description

`modules/swap.nix` declares:

```nix
swapDevices = [
  {
    device = "/var/lib/swapfile";
    size = 32 * 1024;
    priority = 10;
  }
];
```

The fresh installer separately creates a swap partition, defaulting to 16 GiB.

### Failure mode

A newly installed system may have:

```text
16 GiB swap partition
+
32 GiB /var/lib/swapfile
=
48 GiB swap
```

The common module also assumes the machine has 32 GiB RAM and enough disk capacity.

### Required fix

Remove `modules/swap.nix` from common `configuration.nix`.

Swap belongs to machine-local storage policy.

Choose one source of truth:

- Installer-generated swap partition from `hardware-configuration.nix`, or
- Machine-local swapfile configuration.

If the repository wants reusable presets, create optional modules:

```text
modules/machine-presets/swapfile-16g.nix
modules/machine-presets/swapfile-32g.nix
```

but do not import them globally.

### Acceptance criteria

- Common config does not create swap.
- Fresh installer produces exactly the swap configuration selected by the user.
- Rebuilding after installation does not add a second swap device.

---

## P1-05 — Bootloader policy is stored in common `base.nix`

### Description

`modules/base.nix` forces:

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

These are machine/installation choices.

### Failure mode

The configuration assumes:

- UEFI.
- systemd-boot.
- Writable EFI variables.

This may not fit:

- Legacy BIOS.
- GRUB installations.
- Certain dual-boot layouts.
- VMs.
- Special EFI layouts.

### Required fix

Move bootloader configuration into generated `.machine/configuration.nix` or a machine-selected boot module.

For the project's own installer, it is fine to choose systemd-boot as the installer's policy because that installer controls the disk layout. The mistake is making it a universal common-module assumption.

### Acceptance criteria

- `modules/base.nix` is independent of bootloader implementation.
- Existing machines can use their own bootloader while still importing the portable repo.
- Installer-created machines explicitly choose the bootloader in `.machine`.

---

## P1-06 — Machine-specific kernel parameters are globally synced

### Description

`modules/base.nix` contains:

```nix
boot.kernelParams = [
  "usbcore.autosuspend=-1"
  "hid_apple.fnmode=0"
];
```

These change hardware behavior.

### Failure mode

- `usbcore.autosuspend=-1` changes power policy on every target machine.
- `hid_apple.fnmode=0` is meaningful only for relevant keyboard hardware.
- Laptop battery behavior can change unnecessarily.

### Required fix

Move hardware-specific kernel parameters into `.machine/hardware-extra.nix` or opt-in hardware modules.

Keep only parameters that are genuinely required by every supported workstation.

### Acceptance criteria

- Globally imported modules contain no device-specific kernel parameters.
- Machine-specific parameters are visible in machine-local configuration.

---

## P1-07 — `system.stateVersion` is common instead of machine-local

### Description

`modules/base.nix` sets:

```nix
system.stateVersion = "26.05";
```

`system.stateVersion` represents the compatibility baseline of the individual installation, not the current repository release.

### Failure mode

A future machine first installed under a different NixOS baseline inherits the original machine's state version merely by cloning the repo.

### Required fix

Remove `system.stateVersion` from common config.

Generate/store it in `.machine/configuration.nix` during machine installation/bootstrap.

The installer should set the correct intended baseline once and preserve it.

### Acceptance criteria

- Common modules do not define `system.stateVersion`.
- Each machine's ignored configuration defines it explicitly.
- Rebuild/update scripts never automatically bump it.

---

## P1-08 — 9Router mutates `/etc/hosts` although Nix already owns it

### Description

`modules/services.nix` correctly defines required portable host mappings via:

```nix
networking.extraHosts = ''
  127.0.0.1 daily-cloudcode-pa.googleapis.com
  127.0.0.1 cloudcode-pa.googleapis.com
'';
```

But `scripts/init-9router.sh` also:

- Detects `/etc/hosts` symlink.
- Removes it.
- Copies `/etc/static/hosts`.
- Appends host entries manually.

This creates two writers for the same resource.

### Why the host mappings SHOULD remain tracked

These mappings are not machine identity. They are required by the portable 9Router feature.

The correct conclusion is:

- Keep the mappings in the repository.
- Remove runtime mutation of `/etc/hosts`.

### Required fix

Delete the `/etc/hosts` mutation block from `init-9router.sh`.

Replace it with validation:

```bash
require_host_mapping() {
    local domain="$1"
    if ! getent hosts "$domain" | grep -q '127\.0\.0\.1'; then
        error "Required 9Router host mapping is missing for $domain. Run ./scripts/build.sh switch."
    fi
}
```

Nix becomes the only writer.

### Acceptance criteria

- `init-9router.sh` never deletes/replaces/appends `/etc/hosts`.
- `networking.extraHosts` remains tracked.
- Re-running 9Router init cannot change Nix-managed hosts.
- Doctor/preflight verifies required mappings.

---

## P1-09 — 9Router creates `/usr/bin/lsof` and may install through `nix profile`

### Description

The repo already installs `lsof` through `environment.systemPackages`.

`init-9router.sh` also:

```bash
nix profile add nixpkgs#lsof
```

when missing, then:

```bash
sudo mkdir -p /usr/bin
sudo ln -sfn "$LSOF_BIN" /usr/bin/lsof
```

This gives the same dependency multiple owners.

### Failure mode

- System package state and user profile state can disagree.
- `/usr/bin` is mutated outside declarative Nix configuration.
- Fresh machines depend on imperative compatibility hacks.
- Cleanup/rebuild can produce unexpected path changes.

### Required fix

First confirm exactly why 9Router needs `/usr/bin/lsof`.

If it accepts `PATH`, keep only:

```nix
environment.systemPackages = [ pkgs.lsof ];
```

If upstream hardcodes `/usr/bin/lsof`, create a wrapper/patch for 9Router instead of mutating the global filesystem.

Recommended long-term direction:

- Package/wrap 9Router with Nix.
- Patch the lookup to `lib.getExe pkgs.lsof` or provide a controlled wrapper PATH.
- Remove `nix profile add` and `/usr/bin` writes.

### Acceptance criteria

- `init-9router.sh` never installs `lsof`.
- `init-9router.sh` never writes `/usr/bin`.
- Exactly one tracked package declaration provides `lsof`.

---

## P1-10 — 9Router uses `9router@latest`

### Description

Current code runs:

```bash
npm i -g 9router@latest
```

OmniRoute is pinned, but 9Router is not.

### Failure mode

The same git commit can install different software on different days.

This breaks:

- Reproducibility.
- Rollback expectations.
- Testing assumptions.
- Compatibility with the repo's patch logic.

It also increases supply-chain/update exposure because every fresh bootstrap trusts the newest release.

### Required fix

Add a pinned version to `resources/ai/gateway.env`:

```bash
ROUTER_9_PINNED_VERSION="x.y.z"
```

Install:

```bash
npm i -g "9router@$ROUTER_9_PINNED_VERSION"
```

Verify the installed version before deciding to reinstall.

Best long-term fix: package 9Router using Nix with a locked source/hash.

### Acceptance criteria

- No `@latest` remains in bootstrap/install paths.
- `resources/ai/gateway.env` is the version source of truth.
- Doctor reports the actual vs expected version.
- Tests cover version mismatch behavior.

---

## P1-11 — 9Router patches installed npm internals with `sed`

### Description

After installing 9Router, the initializer finds:

```text
9router/app/.next-cli-build/server/app/api/cli-tools/antigravity-mitm/route.js
```

and applies a string replacement with `sed`.

### Failure mode

The patch depends on:

- Exact upstream package layout.
- Exact minified/generated text.
- Exact JS expression.

A minor upstream release can:

- Move the file.
- Change minification.
- Change the expression.
- Make the patch silently not apply.

Combined with `@latest`, this is especially fragile.

### Required fix

Short-term:

1. Pin 9Router.
2. Define the expected upstream version.
3. Fail if the expected patch target/pattern is absent when the pinned version requires the patch.
4. Verify the patched output.

Long-term:

- Maintain a proper source patch in a Nix package/derivation, or
- Upgrade to an upstream release containing the fix and remove the patch.

Do not patch mutable global installation state after installation if a reproducible package patch is possible.

### Acceptance criteria

- Patch behavior is tied to an exact 9Router version.
- Unexpected upstream layout causes a clear failure rather than silent success.
- Once upstream fixes the bug, the local patch is deleted.

---

## P1-12 — No end-to-end fresh-machine integration test

### Description

The repository does have:

```text
scripts/test-isolated.sh
```

This is valuable, but it mainly validates:

- Shell syntax.
- JSON/JSONC.
- Keymap generation.
- Neovim.
- Editor symlink behavior.
- Selected compliance checks.

It does **not** execute the full bootstrap or installer orchestration.

That is why the `install_user` runtime bug can coexist with passing syntax checks.

### Required fix

Add two new test layers.

#### A. Bootstrap integration test

Use a temporary HOME and mocked system commands.

Verify:

- Arbitrary username.
- Arbitrary hostname.
- `.machine` generation.
- No tracked machine-specific file modification.
- Config symlinks.
- Existing config backups.
- Rebuild command constructed correctly.
- Gateway reconciliation invoked only after successful rebuild.
- Re-running bootstrap is idempotent.

#### B. Installer orchestration test

Mock all destructive commands.

Verify:

- User and hostname values survive all functions.
- Correct target paths are generated.
- Swap choice produces one source of truth.
- No real block device is touched.

Optional high-confidence stage:

#### C. NixOS VM test

Boot a NixOS VM, import the portable configuration and assert:

- Evaluation succeeds.
- Portable services start.
- No personal user/hardware assumptions are required.

### Acceptance criteria

A bug equivalent to P0-01 must cause CI to fail before merge.

---

# 5. P2: important maintainability and convergence problems

## P2-01 — 9Router CA trust is managed by two mechanisms

### Description

Tracked Nix config uses:

```nix
security.pki.certificateFiles = [
  ../resources/certs/9router-rootCA.crt
];
```

`init-9router.sh` also copies the cert into:

```text
/usr/local/share/ca-certificates/9router-root-ca.crt
```

### Clarification

The public certificate SHOULD be tracked because 9Router requires it.

The private key MUST remain secret/local.

The problem is duplicate trust ownership, not the fact that the public cert is synced.

### Required fix

Determine whether 9Router upstream merely checks for the literal file path or actually needs the OS trust mechanism there.

If the literal path is required:

- Keep Nix as the real trust-store owner.
- Treat `/usr/local/share/...` as an explicitly documented compatibility shim.
- Prefer generating the compatibility file declaratively if NixOS supports a clean mechanism.

If the literal path is not required, delete the imperative copy.

### Acceptance criteria

Documentation clearly states:

```text
Public CA: tracked and trusted declaratively.
Private CA key: local/encrypted only.
Compatibility path: present only if upstream strictly requires it.
```

---

## P2-02 — `bootstrap.sh` has too many responsibilities

### Description

`bootstrap.sh` currently performs:

- Environment validation.
- Machine detection.
- Hardware config generation.
- User/hostname config generation.
- Wallpaper copy.
- App config linking.
- Git/SSH config linking.
- CLI linking.
- systemd user-unit linking.
- npm prefix configuration.
- Ownership repair.
- NixOS rebuild.
- Editor sync.
- AI gateway reconciliation.

This makes the script difficult to test and retry safely.

### Required fix

Make `bootstrap.sh` an orchestrator.

Suggested layout:

```text
scripts/
  bootstrap.sh
  preflight.sh
  lib/
    common.sh
    machine.sh
    links.sh
    ownership.sh
```

Suggested top-level flow:

```bash
main() {
    preflight
    detect_target_user
    generate_machine_state
    link_portable_configs
    rebuild_system
    sync_editors
    reconcile_ai_gateways
    run_doctor
}
```

Each operation should have one clearly defined responsibility.

### Acceptance criteria

- `bootstrap.sh` reads like a workflow, not an implementation dump.
- Shared `safe_link`, logging and target-user logic are not duplicated across scripts.
- Individual stages can be tested separately.

---

## P2-03 — Bootstrap accepts `aarch64` while flake is x86_64-centric

### Description

`bootstrap.sh` accepts:

```text
x86_64
aarch64
```

But `flake.nix` defines:

```nix
nixpkgs.legacyPackages.x86_64-linux
formatter.x86_64-linux
devShells.x86_64-linux
```

README also describes an x86_64 workstation.

### Required fix

Choose one explicit contract.

#### Option A: x86_64 only

Recommended until ARM is tested.

Reject ARM:

```bash
[ "$(uname -m)" = "x86_64" ] ||
  error "Unsupported architecture. This repository currently supports x86_64-linux only."
```

#### Option B: real multi-architecture support

Make flake outputs system-aware and test both architectures.

Do not advertise support through bootstrap detection unless the whole system supports it.

### Acceptance criteria

README, bootstrap, flake and tests agree on supported architectures.

---

## P2-04 — Greeter chooses the first normal user

### Description

`modules/desktop.nix` computes all normal users and uses:

```nix
builtins.head normalUsers
```

for `passwordless-sync-users`.

This is not a reliable definition of the machine's primary desktop user.

### Required fix

Do not derive machine identity from common module enumeration.

Move the chosen sync user to machine config, or expose a module option:

```nix
dotfiles.primaryUser = "...";
```

The machine-local config sets the option. Common desktop config consumes it.

### Acceptance criteria

- Multiple-user machines have deterministic intended behavior.
- The common module does not guess the primary user.

---

## P2-05 — `safe_link` does not validate source existence

### Description

Bootstrap and editor sync can call `safe_link` with a source that does not exist.

`ln -sfn` can create a broken symlink.

### Required fix

Centralize `safe_link` and validate the source:

```bash
safe_link() {
    local src="$1"
    local dest="$2"

    [ -e "$src" ] || error "Cannot link missing source: $src"
    ...
}
```

For optional resources, check existence before calling `safe_link`.

### Acceptance criteria

- Required missing source causes immediate failure with the exact path.
- Optional source is explicitly skipped.
- Doctor should never be the first place a broken repo-owned symlink is discovered.

---

## P2-06 — Bootstrap performs broad recursive ownership repairs

### Description

Bootstrap contains recursive ownership changes such as:

```text
$USER_HOME/.config
$USER_HOME/.local/lib/node_modules
```

Some calls suppress failure with `|| true`.

### Failure mode

A script intended to configure dotfiles can rewrite ownership for unrelated application files under `.config`.

### Required fix

Only chown paths created by the current operation.

Prefer:

- Run user-level steps as the target user.
- Avoid creating user files as root.
- Use `install -o/-g` where appropriate.
- If repair is required, scope it to exact repo-owned paths.

Do not recursively `chown ~/.config`.

### Acceptance criteria

- No blanket recursive ownership repair of the user's whole config directory.
- Bootstrap works both when invoked normally and through sudo without leaving root-owned user files.

---

## P2-07 — `build.sh` advertises rollback but does not restore

### Description

The function:

```bash
rollback_on_error() {
    warn "Build encountered an error. Restoring from snapshot ..."
}
```

does not restore any file.

### Risk

The function name and message imply a safety guarantee that does not exist.

### Required fix

Choose one:

#### Option A: implement actual restoration

Restore the exact files/directories that were snapshotted.

#### Option B: remove rollback wording

Rename to:

```bash
report_backup_on_error
```

and state:

```text
Build failed. A pre-build backup is available at ...
```

Option B is safer unless a real restoration protocol is designed.

### Acceptance criteria

Messages and behavior match exactly.

---

## P2-08 — No explicit preflight stage before system mutation

### Description

Bootstrap verifies only a small set of commands before it starts generating files and linking configuration.

The installer similarly discovers some problems after destructive operations begin.

### Required fix

Create a non-mutating preflight that validates:

- Supported architecture.
- Required repository files.
- Required scripts are executable/readable.
- `flake.lock` exists.
- Required certificate exists.
- Machine config destination is writable.
- Nix evaluation of common modules succeeds.
- Required host mappings are declared.
- Required gateway config variables are present.
- User/hostname inputs are valid.
- For installer: disk tooling is present before wiping anything.

Run preflight before mutation.

### Acceptance criteria

Any predictable configuration/tooling error fails before disk formatting or system changes.

---

## P2-09 — Deployment uses legacy `nixos-rebuild -I` instead of a flake target

### Description

The repo has `flake.nix` and `flake.lock`, but operational rebuild uses:

```bash
sudo nixos-rebuild switch -I "nixos-config=$MACHINE_CONFIG"
```

The flake's `nixosConfigurations.check` is mainly an evaluation target, not the authoritative deployment target.

### Risk

- Flake locking and actual deployment are not one coherent entrypoint.
- It is harder to reason about exactly which inputs are used.
- Common evaluation and machine deployment paths can diverge.

### Required fix

Design a machine flake output that consumes ignored/generated machine configuration without committing hardware identity.

Possible pattern:

```nix
nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
  modules = [
    ./configuration.nix
    ./.machine/configuration.nix
  ];
};
```

Because flakes normally only see tracked/source-tree inputs, design this carefully. A practical option is a local wrapper flake in `.machine`, or continue path-based evaluation but make the choice explicit and documented.

The important requirement is a single authoritative deployment model rather than half-flake/half-legacy semantics.

### Acceptance criteria

- `check` and actual deployment evaluate the same common module graph.
- Documentation explains exactly how machine-local ignored files participate.
- No hidden dependency on ambient NIX_PATH.

---

## P2-10 — Secret archive policy and docs are inconsistent

### Description

`secrets.sh` says the encrypted result can be committed/synced, while `.gitignore` ignores `secrets.enc`.

The repository also uses `secrets.vault`/vault concepts.

### Risk

Users and automation cannot tell which encrypted artifact is:

- Local-only.
- Safe to commit.
- Intended for cross-machine transfer.
- Canonical.

### Required fix

Define a strict policy, for example:

```text
secrets/
  plaintext working secrets
  always ignored

secrets.age
  optional encrypted portable secrets
  tracked only if the project explicitly wants encrypted secrets in git

secrets.vault
  local encrypted full-state backup
  always ignored
```

Or keep everything encrypted local-only, but update `secrets.sh` messages accordingly.

### Acceptance criteria

README, scripts and `.gitignore` describe exactly one consistent policy.

---

## P2-11 — Main branch lacks protection and no tracked CI workflow is present

### Description

At reviewed commit, the `main` branch reports protection disabled.

The repository root has no `.github` directory, so the strong local `scripts/check.sh` gate is not enforced by a tracked GitHub Actions workflow.

### Risk

A change can reach `main` without:

- `shellcheck`
- `nixfmt`
- `nix flake check`
- systemd verification
- unit tests

### Required fix

Add a CI workflow that runs at minimum:

```text
scripts/check.sh
scripts/test-isolated.sh
new bootstrap integration test
new installer orchestration test
```

Then protect `main` and require the CI check before merge.

### Acceptance criteria

- Pull requests cannot merge to `main` while required checks fail.
- Direct accidental pushes are restricted according to project policy.

---

# 6. P3: clean-code and clarity improvements

## P3-01 — Duplicate `lsof` in `modules/packages.nix`

### Description

`lsof` appears more than once in `environment.systemPackages`.

### Required fix

Keep one declaration and attach the 9Router requirement comment to that single entry.

---

## P3-02 — Unused `pkgs` argument in `modules/services.nix`

### Description

The module starts with:

```nix
{ pkgs, ... }:
```

but does not need `pkgs` in the reviewed implementation.

### Required fix

Use:

```nix
{ ... }:
```

until the argument is actually needed.

---

## P3-03 — Common modules mix unrelated responsibilities

### Description

`services.nix` currently combines:

- Docker.
- Bluetooth.
- seat management.
- device-specific udev.
- KDE Connect.
- PipeWire.
- power.
- storage.
- WARP.
- 9Router DNS.

This makes it difficult to separate portable features from machine hardware.

### Required fix

Split by responsibility, for example:

```text
modules/
  services/
    containers.nix
    audio.nix
    connectivity.nix
    storage.nix
    ai-gateways.nix
  hardware/
    weikav-nut75.nix
```

Do not split into tiny files merely for aesthetics. Split where ownership/lifecycle differs.

---

## P3-04 — Comments/documentation contradict implementation

### Examples

`services.nix` says:

```text
DO NOT manually edit /etc/hosts
```

while `init-9router.sh` manually edits it.

README says machine hardware stays separated, but common modules currently include:

- Intel GPU policy.
- WEIKAV device rules.
- bootloader.
- hardware kernel params.
- swap assumptions.

### Required fix

Fix implementation first, then update comments/docs to match.

Never use comments to describe an architecture the code does not actually implement.

---

## P3-05 — Some `|| true` paths suppress meaningful failures

### Description

Some cleanup/ownership/setup operations intentionally use `|| true`.

Some are valid best-effort operations, but others can hide incomplete configuration.

### Required fix

Classify every suppressed error:

```text
BEST_EFFORT
  Failure is harmless and documented.

REQUIRED
  Failure must abort.

OPTIONAL_FEATURE
  Failure must produce a warning with remediation.
```

Examples:

- `chown` of a required repo-owned symlink should not silently fail.
- `loginctl enable-linger` failure should at least warn if persistent gateway startup depends on it.
- Cleanup commands may reasonably be best effort.

### Acceptance criteria

Every remaining `|| true` has an adjacent comment explaining why failure is safe to ignore.

---

## P3-06 — `test-isolated.sh` name/scope can create false confidence

### Description

The script reports:

```text
ALL ISOLATED TESTS PASSED
ZERO HOST POLLUTION
```

but its coverage is concentrated on editor/config validation.

It does not simulate complete bootstrap/installer behavior.

### Required fix

Either:

- Rename it to reflect its scope, such as `test-config-isolated.sh`, or
- Expand it and split dedicated tests for bootstrap and installer.

Do not present editor isolation tests as proof that fresh-machine installation is safe.

---

# 7. Recommended target architecture

```text
dotfiles/
├── flake.nix
├── flake.lock
├── configuration.nix
│
├── modules/
│   ├── base.nix
│   ├── packages.nix
│   ├── desktop.nix
│   ├── fonts.nix
│   ├── i18n.nix
│   ├── shell.nix
│   ├── nvim.nix
│   ├── lsp.nix
│   ├── godot.nix
│   ├── zellij.nix
│   │
│   ├── services/
│   │   ├── containers.nix
│   │   ├── audio.nix
│   │   ├── desktop-services.nix
│   │   └── ai-gateways.nix
│   │
│   └── hardware/
│       ├── intel-graphics.nix
│       └── weikav-nut75.nix
│
├── resources/
│   ├── ai/
│   │   └── gateway.env
│   ├── certs/
│   │   └── 9router-rootCA.crt
│   └── ...
│
├── scripts/
│   ├── bootstrap.sh
│   ├── preflight.sh
│   ├── build.sh
│   ├── doctor.sh
│   ├── reconcile-ai-gateways.sh
│   ├── init-9router.sh
│   ├── init-omniroute.sh
│   └── lib/
│       ├── common.sh
│       ├── target-user.sh
│       ├── machine.sh
│       └── links.sh
│
├── tests/
│   ├── bootstrap/
│   ├── installer/
│   ├── ai/
│   ├── vault/
│   └── zellij/
│
└── .machine/                    # ignored
    ├── configuration.nix
    ├── hardware-configuration.nix
    ├── hardware-extra.nix
    └── identity.nix
```

---

# 8. Desired ownership model

## Common tracked state

`configuration.nix` should describe a portable workstation.

Examples:

```text
packages
desktop software
shell/editor config
portable services
9Router feature requirements
OmniRoute feature requirements
9Router host mappings
public Root CA
```

## Machine-local state

`.machine/` should contain:

```text
hostname
primary user
stateVersion
bootloader
hardware-configuration
GPU module selection
device-specific modules
swap/storage policy
machine-specific kernel params
```

## Runtime secret state

Keep outside tracked public config:

```text
9Router private CA key
OmniRoute STORAGE_ENCRYPTION_KEY
OmniRoute SQLite DB
SSH private keys
browser/app sessions
Wi-Fi credentials
```

---

# 9. Detailed implementation order

## Phase 0 — Stop destructive/runtime blockers

1. Fix P0-01 installer user scope.
2. Add installer mock integration test.
3. Do not modify any other architecture until the destructive installer flow has a regression test.

## Phase 1 — Establish portable vs machine-local boundary

1. Remove `users.users.loc`.
2. Move `system.stateVersion`.
3. Move bootloader.
4. Move swap.
5. Move Intel GPU config.
6. Move WEIKAV rules/seat workaround.
7. Move hardware-specific kernel params.
8. Generate or select these from `.machine`.

After this phase, common config should evaluate without knowing the physical machine or username.

## Phase 2 — Make 9Router reproducible

1. Keep `networking.extraHosts` in tracked Nix config.
2. Delete direct `/etc/hosts` mutation.
3. Remove `nix profile add nixpkgs#lsof`.
4. Remove `/usr/bin/lsof` mutation.
5. Pin 9Router version.
6. Make the patch version-specific or package it properly.
7. Clarify CA trust ownership.
8. Add version/host/cert health checks.

## Phase 3 — Refactor orchestration

1. Add `preflight.sh`.
2. Centralize logging.
3. Centralize target-user detection.
4. Centralize `safe_link`.
5. Make `bootstrap.sh` orchestration-only.
6. Narrow ownership operations.
7. Fix rollback semantics.

## Phase 4 — Tests and CI

1. Bootstrap integration test.
2. Installer orchestration test.
3. Keep existing isolated/editor tests.
4. Add CI.
5. Require CI on `main`.

## Phase 5 — Documentation cleanup

1. Update README architecture.
2. Document portable vs machine-local boundary.
3. Document secrets policy.
4. Document supported architecture.
5. Document 9Router CA/private key model.
6. Remove stale contradictory comments.

---

# 10. Suggested fresh-machine flow after remediation

```text
clone repository
      |
      v
scripts/bootstrap.sh
      |
      +--> preflight (read-only)
      |
      +--> detect target user / hostname
      |
      +--> generate .machine/
      |      |
      |      +-- hardware-configuration.nix
      |      +-- identity.nix
      |      +-- stateVersion
      |      +-- optional hardware imports
      |
      +--> link portable repo configuration
      |
      +--> rebuild system
      |
      +--> sync editor state
      |
      +--> reconcile AI gateways
      |      |
      |      +-- pinned 9Router
      |      +-- pinned OmniRoute
      |      +-- validate hosts
      |      +-- validate CA
      |      +-- validate loopback/service health
      |
      +--> doctor
      |
      v
READY
```

No bootstrap step should:

```text
copy another machine's hardware configuration
hardcode a personal username
copy Wi-Fi credentials
force Intel GPU settings on every machine
force one machine's swap policy
replace /etc/hosts manually
create unmanaged /usr/bin files
install mutable @latest dependencies
```

---

# 11. Definition of Done

The remediation is complete only when all conditions below are true.

## Portability

- [ ] Common tracked config contains no personal username.
- [ ] Common tracked config contains no hostname.
- [ ] Common tracked config contains no generated hardware config.
- [ ] GPU/device quirks are opt-in machine modules.
- [ ] Swap and bootloader are machine-local.
- [ ] `system.stateVersion` is machine-local.
- [ ] Wi-Fi credentials/profiles are not tracked.

## 9Router / OmniRoute

- [ ] 9Router required host mappings remain tracked.
- [ ] `/etc/hosts` is only managed by Nix.
- [ ] 9Router version is pinned.
- [ ] OmniRoute version remains pinned.
- [ ] No script creates `/usr/bin/lsof`.
- [ ] 9Router patch is deterministic/version-bound or removed.
- [ ] Public CA is tracked.
- [ ] Private CA key is never tracked.
- [ ] OmniRoute secrets/database are never tracked.
- [ ] Both services pass doctor health checks.

## Installer/bootstrap

- [ ] Fresh installer has no variable-scope bug.
- [ ] Installer tests run with mocked destructive commands.
- [ ] Bootstrap can run twice without corrupting state.
- [ ] Required source files are checked before symlinking.
- [ ] Preflight runs before mutation.
- [ ] Bootstrap does not broadly chown unrelated user directories.
- [ ] Final bootstrap automatically runs doctor or equivalent critical checks.

## Syntax / QA

- [ ] `bash -n` passes.
- [ ] `shellcheck` passes.
- [ ] `nixfmt --check` passes.
- [ ] `nix flake check` passes.
- [ ] systemd unit validation passes.
- [ ] existing Vault tests pass.
- [ ] existing Zellij tests pass.
- [ ] existing OmniRoute tests pass.
- [ ] isolated config/editor tests pass.
- [ ] new bootstrap integration tests pass.
- [ ] new installer orchestration tests pass.

## Repository governance

- [ ] CI runs required checks on pull requests.
- [ ] `main` requires successful checks before merge.
- [ ] README matches actual architecture.
- [ ] Secrets policy is unambiguous.

---

# 12. Final assessment

The repository has a solid portable configuration core and its QA is materially stronger after PR #42. In particular:

- OmniRoute loopback isolation is explicitly checked.
- OmniRoute is pinned.
- AI gateway reconciliation has a single orchestration entrypoint.
- Editor extensions are checksum-pinned.
- Zellij plugins are pinned.
- Shell/Nix/systemd/config syntax checks are extensive.
- `.machine/` exists as the correct conceptual place for non-portable state.

The largest remaining problem is **boundary leakage**: several settings that belong to one machine still live in globally imported modules.

The second largest problem is **imperative duplication around 9Router**: Nix describes the desired state, while the initializer also mutates the same system resources.

The third largest problem is **orchestration coverage**: current tests validate many components, but they do not yet prove that a fresh machine can complete the real installer/bootstrap flow.

Fixing P0 and P1 first will produce the biggest reliability improvement. After those items, the repository will be much closer to the intended model:

> **Portable workstation state is synchronized; physical-machine identity and hardware state remain local; required portable features such as 9Router carry all of their reproducible dependencies with them.**
