# Homelab GitOps (Docker Swarm)

This repository manages a homelab using GitOps practices with Docker Swarm.

## Goals

- Keep infrastructure as code, versioned in Git.
- Start with core services: AdGuard Home (DNS/DHCP) and Nginx.
- Scale by adding new stacks and configurations over time.

## Repository Structure

```
.
|-- configs/
|   `-- nginx/
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
- Add future stacks under `stacks/<name>/docker-stack.yml` and deploy with the same script.
