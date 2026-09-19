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

* `resources/systemd/user/omniroute.service`: Declarative systemd user service binding OmniRoute to `127.0.0.1:20129`.
* `scripts/init-omniroute.sh`: Automated installer, port configuration, and service bootstrapper.
* `scripts/sync-omniroute.sh`: Declarative configuration bundle export/import and vault synchronization.
* `resources/omniroute/bundle.json`: Declarative export of settings, combos, keys, policies, and skills.
* `~/.omniroute/`:
  * `.env`: Contains `PORT=20129` and `STORAGE_ENCRYPTION_KEY`.
  * `storage.sqlite`: Local encrypted database containing all GUI customizations, accounts, and provider configurations (synced via `vault backup`).

---

## Daily Workflow & CLI Commands

### 1. Initialize or Reinstall
```bash
init-omniroute
```
This ensures Node.js dependencies, configures port `20129`, and starts the systemd service.

### 2. Service Management
```bash
systemctl --user status omniroute
systemctl --user restart omniroute
journalctl --user -u omniroute -f
```

### 3. Sync Settings & Providers
```bash
# Export configuration bundle to resources/omniroute/bundle.json
sync-omniroute export

# Import bundle back into local instance
sync-omniroute import

# Sync entire database and tokens into encrypted vault
vault backup
```

### 4. Health Check
```bash
doctor
```
The dotfiles system doctor checks that both 9Router (`20128`) and OmniRoute (`20129`) are healthy and non-conflicting.
