---
name: linux-server-admin
description: "Linux server administration & systems operations: systemd service management, journalctl logging, Nginx/Caddy reverse proxy tuning, TLS certificate automation, sysctl kernel optimization, and socket activation. Use when managing, configuring, or tuning Linux servers."
---

# Linux Server Administration & System Operations

Standards for configuring, maintaining, and tuning production Linux servers for high reliability.

## Core Rules

1. **Systemd Service Sandboxing**:
   - Run services under dedicated non-root users (`User=app`, `Group=app`).
   - Sandbox unit files with systemd security primitives:
     ```ini
     ProtectSystem=strict
     ProtectHome=true
     NoNewPrivileges=true
     PrivateTmp=true
     Restart=on-failure
     RestartSec=5s
     ```

2. **Reverse Proxy & TLS Hygiene**:
   - Terminate TLS at the reverse proxy (Nginx or Caddy) using modern TLS 1.3 ciphers and automated Let's Encrypt renewal.
   - Configure proxy headers correctly (`X-Forwarded-For`, `X-Forwarded-Proto`, `X-Real-IP`).
   - Tune buffer sizes and connection timeouts to guard against Slowloris and resource exhaustion.

3. **Log Slicing & Observability**:
   - Query logs efficiently via `journalctl -u <service> -n 100 --no-pager` or `journalctl -u <service> --since "1 hour ago"`.
   - Rotate logs via `logrotate` or configure systemd journal vacuuming (`SystemMaxUse=500M`).

4. **Kernel & Network Optimization (`sysctl`)**:
   - Tune file descriptor limits (`fs.file-max`, `nofile` limits in `/etc/security/limits.conf`).
   - Enable TCP BBR congestion control (`net.ipv4.tcp_congestion_control=bbr`) and optimize socket buffers for high-concurrency servers.
