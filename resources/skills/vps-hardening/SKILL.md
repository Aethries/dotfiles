---
name: vps-hardening
description: "Linux VPS and server hardening: SSH security, UFW firewall, Fail2ban, automatic updates, and systemd unit sandboxing. Use when securing Linux servers or production virtual private servers."
---

# Linux VPS Hardening & Security

Production baseline checklist for securing Linux Virtual Private Servers and cloud compute instances.

## Core Rules

1. **SSH Hardening**:
   - Disable password authentication: `PasswordAuthentication no`.
   - Disable root SSH login: `PermitRootLogin no`.
   - Restrict authentication to modern key algorithms only (Ed25519 or ECDSA).
   - Set idle session timeouts: `ClientAliveInterval 300` and `ClientAliveCountMax 2`.
2. **Firewall & Network Isolation (UFW / iptables)**:
   - Default deny incoming: `ufw default deny incoming` and `ufw default allow outgoing`.
   - Allow strictly required ports only: SSH, HTTP (80), HTTPS (443).
   - Rate limit SSH connection bursts: `ufw limit ssh`.
3. **Intrusion Prevention & Brute-Force Defense (Fail2ban)**:
   - Configure Fail2ban jails for SSH, Nginx, and application auth endpoints.
   - Set aggressive ban times for repeat offenders (e.g. 1 hour ban after 5 failed attempts within 10 minutes).
4. **Systemd Sandboxing & Non-Root Services**:
   - Run all application services under dedicated unprivileged system users (`User=appuser`).
   - Enable systemd security directives in `.service` units:
     ```ini
     ProtectSystem=strict
     ProtectHome=true
     NoNewPrivileges=true
     PrivateTmp=true
     ProtectKernelTunables=true
     ProtectControlGroups=true
     ```
5. **Automated Security Patching**:
   - Enable `unattended-upgrades` on Debian/Ubuntu or automated update timers on NixOS/Alpine for critical security errata.
