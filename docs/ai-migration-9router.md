# 9router to OmniRoute migration inventory

This file is the compatibility record for the removed 9router integration.
It is intentionally the only normal repository location that names the old
runtime after migration.

| Former touchpoint | Former purpose | Replacement | Cleanup/state policy |
| --- | --- | --- | --- |
| `scripts/init-9router.sh` | Mutable npm install, CA setup, hosts mutation, patching installed package | `pkgs/omniroute.nix`, `scripts/ai.sh`, managed service | Removed from normal runtime. The legacy script is never recreated. |
| `resources/systemd/user/9router.service` | User service on port 20128 | `resources/systemd/user/omniroute.service` | Removed from repo; existing user unit is only handled by explicit migration/cleanup. |
| `modules/services.nix` host entries | Redirected Cloud Code hostnames to MITM proxy | No host override; OmniRoute is an ordinary loopback HTTP gateway | Removed. Bootstrap never edits `/etc/hosts`. |
| `modules/base.nix` certificate | Trusted 9router MITM root CA | No MITM CA required by OmniRoute | Removed from Nix configuration. Existing system trust is left untouched automatically. |
| `modules/packages.nix` `nssTools`/9router comments | Browser trust and `lsof` workaround | Standard Nix package closure and loopback service | Removed; `lsof` remains only as a general utility. |
| `scripts/bootstrap.sh` legacy links | Exposed mutable `init-9router` aliases | `ai`, `init-omniroute`, `sync-ai` links to repo scripts | Removed. |
| `scripts/doctor.sh` legacy checks | Reported 9router service and aliases | AI doctor checks OmniRoute, RTK, Caveman, CodeGraph, MCP, and Bifrost | Removed. |
| `scripts/vault.sh` `.9router` lifecycle | Backed up and restarted old runtime | Backs up `~/.local/state/omniroute` data and restarts OmniRoute only when active before restore | Existing `~/.9router` data is not deleted by bootstrap. |
| `scripts/secrets.sh` comment | Described old secret filename | Generic provider secret description | Updated. |

## Existing-machine migration

The migration commands are deliberately separate from bootstrap:

```bash
./scripts/ai.sh migrate-9router --dry-run
./scripts/ai.sh migrate-9router --apply
./scripts/ai.sh cleanup-9router --dry-run
./scripts/ai.sh cleanup-9router --apply-system-cleanup
```

Dry-run is read-only. Apply migration stops the old user service if present,
starts OmniRoute, and probes its health endpoint. It does not delete credentials
or old trust state. Cleanup moves home-owned legacy state to a dated backup;
system certificates and credentials remain untouched unless a future explicit
operator action handles them.

The deleted runtime files remain represented here because rollback and review
need an auditable inventory. They are not executable dependencies.
