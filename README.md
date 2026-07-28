# Homelab GitOps (Docker Swarm)

This repository manages a homelab using GitOps practices with Docker Swarm.

## Goals

- Keep infrastructure as code, versioned in Git.
- Start with core services: AdGuard Home (DNS/DHCP) and Nginx.
- Use `.arpa` local domains (for example `adguard.app.arpa`).
- Scale by adding new stacks and configurations over time.

## Repository Structure

```
.
|-- configs/
|   `-- nginx/
|       |-- adguard.app.arpa.conf
|       `-- default.conf
|-- scripts/
|   |-- deploy.sh
|   `-- remove.sh
`-- stacks/
    `-- core/
        |-- .env.example
        `-- docker-stack.yml
```

## Prerequisites

- Docker Engine in Swarm mode (`docker swarm init` on the manager)
- A manager node where the stack can run

## Quick Start

1. Copy environment template if needed:

   ```bash
   cp stacks/core/.env.example stacks/core/.env
   ```

2. Deploy the core stack:

   ```bash
   ./scripts/deploy.sh core
   ```

3. Check services:

   ```bash
   docker stack services core
   ```

4. Remove the stack:

   ```bash
   ./scripts/remove.sh core
   ```

## Notes

- AdGuard is configured as a single replica and pinned to a manager node by default.
- DHCP in containers can require network and host-level adjustments depending on your LAN setup.
- The setup wizard is exposed on `http://<node-ip>:3000`.
- AdGuard main UI is exposed on `http://<node-ip>:8080` and proxied by Nginx at `http://adguard.app.arpa`.
- Use local domains under `.arpa` (example zone: `app.arpa`), and avoid `.home`.
- Add future stacks under `stacks/<name>/docker-stack.yml` and deploy with the same script.

## Local Domain Pattern

Recommended pattern:

- `adguard.app.arpa`
- `nginx.app.arpa`
- `portainer.app.arpa`

Inside AdGuard DNS, create `A` records for these names pointing to the Swarm manager IP.

## DHCP Migration Plan (Gradual)

1. Keep DHCP on the router for now and use AdGuard only as DNS.
2. Set router DNS to the AdGuard host IP.
3. Validate local records and DNS filtering behavior.
4. Schedule a migration window.
5. Disable router DHCP.
6. Enable DHCP in AdGuard with the same gateway/subnet and a safe IP range.
7. Reboot or renew leases on clients.

Only one DHCP server must be active on the LAN at a time.
