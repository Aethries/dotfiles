# OmniRoute Local AI Gateway Configuration

This directory manages the configuration templates and bundles for **OmniRoute**, the local multi-provider AI gateway.

---

## Architecture Overview

OmniRoute coexists with **9Router** in a dual-gateway architecture:

| Gateway | Port | Role / Focus |
| :--- | :---: | :--- |
| **9Router** | `20128` | Google Antigravity & Multi-OAuth pool, MITM interception, web dashboard |
| **OmniRoute** | `20129` | OpenAI-compatible unified proxy, multi-provider routing, custom models, skills |

---

## Key Files & Structure

* `resources/ai/gateway.env`: Single source of truth for ports (`20128`, `20129`), loopback host (`127.0.0.1`), and pinned versions.
* `resources/systemd/user/omniroute.service`: Declarative systemd user service binding OmniRoute strictly to `127.0.0.1:20129` with `UMask=0077`.
* `scripts/reconcile-ai-gateways.sh`: Authoritative reconciliation entry point for both `bootstrap.sh` and `build.sh switch`.
* `scripts/init-omniroute.sh`: Automated installer, pinned package manager (`omniroute@3.8.50`), loopback port configuration, key desync protection, and service bootstrapper.
* `scripts/sync-omniroute.sh`: Scoped state synchronization CLI (`vault backup/restore --scope omniroute`).
* `resources/omniroute/.gitignore`: Excludes `bundle.json`, `*.json`, `*.sqlite*`, and `*.env` to guarantee sensitive credentials are never committed.
* `tests/ai/omniroute_test.sh`: Dynamic integration, security, and port isolation test suite wired directly to `scripts/check.sh`.
* `~/.omniroute/`:
  * `.env`: Contains `PORT=20129`, `HOST=127.0.0.1`, `OMNIROUTE_SERVER_HOST=127.0.0.1`, `API_HOST=127.0.0.1`, `LIVE_WS_HOST=127.0.0.1`, and `STORAGE_ENCRYPTION_KEY`.
  * `storage.sqlite`: Local encrypted database containing all GUI customizations, accounts, and provider configurations (synced safely via `vault backup --scope omniroute`).

---

## State Architecture: Public Tracked vs. Private Encrypted

OmniRoute state follows a strict security architecture:

### 1. Tracked / Public State (Git Repository)
- Service definition template (`resources/systemd/user/omniroute.service` with `UMask=0077`)
- Gateway ports & host bindings (`resources/ai/gateway.env`)
- Pinned version (`3.8.50`)
- Automation & reconciliation scripts (`init-omniroute.sh`, `reconcile-ai-gateways.sh`)

### 2. Private Encrypted State (`secrets.omniroute.vault` or `secrets.vault`)
- `~/.omniroute/storage.sqlite` (SQLite database containing all custom provider configs, accounts, combos, and skills)
- `~/.omniroute/.env` (`STORAGE_ENCRYPTION_KEY` master database decryption key)
- Provider API keys, OAuth access tokens, and refresh tokens
- User sessions and GUI customizations

---

## State Synchronization: Scoped vs. Full-User Operations

* **OmniRoute-Scoped Operations (`sync-omniroute` or `vault --scope omniroute`)**:
  - Uses dedicated file: `secrets.omniroute.vault`
  - Completely isolated: Never touches or overwrites `secrets.vault`.
  ```bash
  sync-omniroute backup   # archives ONLY ~/.omniroute/ into secrets.omniroute.vault (pauses service, checkpoints WAL)
  sync-omniroute restore  # restores ONLY ~/.omniroute/ from secrets.omniroute.vault (never touches SSH, Chrome, 9router, or other apps)
  ```
* **Full-User Vault Operations (`vault.sh`)**:
  - Uses default file: `secrets.vault`
  ```bash
  vault backup            # archives all user credentials (SSH, GPG, Chrome, Keyring, 9router, OmniRoute) into secrets.vault
  vault restore           # restores all user application sessions and profiles from secrets.vault
  ```

---

## Daily Workflow & CLI Commands

### 1. Initialize or Reinstall
```bash
init-omniroute
# Or if resetting an orphaned database with a new encryption key:
init-omniroute --force
```
This guarantees Node.js LTS via `fnm`, pins `omniroute@3.8.50`, configures loopback bindings, protects against key desync, and starts the systemd service.

### 2. Service Management
```bash
omni status     # or systemctl --user status omniroute
omni restart    # or systemctl --user restart omniroute
omni stop       # or systemctl --user stop omniroute
omni logs       # or journalctl --user -u omniroute -f
```

### 3. Sync Settings & Providers
```bash
# Sync entire database, provider accounts, and tokens into encrypted vault (OmniRoute scoped)
sync-omniroute backup   # or: vault backup --scope omniroute

# Restore database and encryption keys on a fresh system (OmniRoute scoped)
sync-omniroute restore  # or: vault restore --scope omniroute
```

### 4. Diagnostics & Testing
```bash
doctor                    # Verifies service status, 127.0.0.1 loopback binding, and coexistence
dotfiles-check            # Runs full repo verification including tests/ai/omniroute_test.sh
```
