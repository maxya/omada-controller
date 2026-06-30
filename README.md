# Omada Controller Docker Compose

Modern Docker Compose stack for the TP-Link Omada Software Controller with external MongoDB, host-network adoption support, backups, preflight checks, and a smaller controller-only image.

This project is a clean, source-built alternative for running Omada Controller in Docker after the LinuxServer image was retired. It is designed for home labs, small networks, and self-hosted Omada SDN deployments that want explicit versions, separate MongoDB lifecycle management, and operational tooling instead of a large all-in-one container.

> Unofficial project. TP-Link Omada Software Controller is proprietary software downloaded from TP-Link. This repository packages and operates it; it does not redistribute or audit TP-Link's application.

## Why This Omada Docker Stack Exists

Many existing Omada Controller Docker images use all-in-one packaging or are no longer maintained. This repository takes a different approach:

- Controller-only Docker image: no bundled MongoDB server inside the Omada container.
- External MongoDB service: official `mongo:8.0`, authentication enabled, separate volumes and healthcheck.
- Docker Compose first: host-mode default for LAN discovery and adoption, bridge/macvlan examples for advanced users.
- Safe operations: preflight checks, backup workflow, support bundle, password rotation, and downgrade guard.
- Explicit Omada versions: no `latest` tag workflow and no automatic major-version upgrades.
- Clean v6 target: starts with Omada Software Controller `6.2.10.17` and avoids legacy v3/v4/v5 entrypoint complexity.

## Quickstart

This project currently uses a source-build workflow. Build the controller image locally before starting the stack; `docker compose pull` is not a supported workflow for the local controller image.

```sh
cp .env.example .env
$EDITOR .env
make preflight
make build
make up
```

Then open:

```text
https://<host-ip>:8043/
```

Configure Omada automatic backups in the UI immediately after first login.

## What You Get

| Area | Default |
| --- | --- |
| Controller | Locally built as `local/omada-controller:${OMADA_VERSION}` |
| Omada version | `6.2.10.17` |
| Database | External `mongo:8.0` service |
| MongoDB exposure | Bound to `127.0.0.1` in host mode |
| Networking | Host mode for easiest Omada device discovery and adoption |
| Data volumes | Separate Omada data, Omada logs, MongoDB data, MongoDB config |
| Java runtime | Java 17 |
| Target platform | `linux/amd64` first |

## Requirements

- Docker Engine with Compose v2.
- `linux/amd64`.
- CPU support required by MongoDB 8.0.
- Official TP-Link Omada Linux `.tar.gz` artifact URL.
- Strong MongoDB passwords in `.env`.

## Configuration

Edit `.env` before building:

```env
OMADA_VERSION=6.2.10.17
OMADA_URL=https://...
OMADA_SHA256=
MONGO_ROOT_PASSWORD=change-this-root-password
OMADA_MONGO_PASSWORD=change-this-omada-password
OMADA_MONGO_BACKUP_PASSWORD=change-this-backup-password
```

Use `OMADA_SHA256` when a trusted checksum is available. If no checksum is available, the build records trust-on-first-use artifact metadata.

## Commands

Run `make help` for the full command contract.

| Command | Purpose |
| --- | --- |
| `make preflight` | Validate Docker, Compose, `.env`, ports, MongoDB bind address, and CPU compatibility |
| `make build` | Build `local/omada-controller:${OMADA_VERSION}` |
| `make up` | Start the host-mode Omada Controller and MongoDB stack |
| `make up-bridge` | Start the bridge-mode stack for advanced deployments |
| `make down` | Stop the host-mode stack |
| `make logs` | Follow controller and MongoDB logs |
| `make smoke` | Check Compose status and the Omada login endpoint |
| `make backup` | Stop the controller, run authenticated `mongodump`, restart the controller |
| `make support-bundle` | Collect redacted diagnostics |
| `make rotate-mongo-password` | Rotate Omada or backup MongoDB user passwords |

## Networking And Device Adoption

Host networking is the default because Omada adoption and discovery are LAN-native workflows. In host mode:

- Omada Controller binds directly on the Docker host network.
- MongoDB is still bound to `127.0.0.1`.
- Device discovery and adoption behave closest to a bare-metal controller.

Bridge mode is available, but adoption usually requires DHCP Option 138, a manual Inform URL, or TP-Link's discovery utility. See [networking.md](docs/networking.md) and [adoption.md](docs/adoption.md).

## Backups And Upgrades

Use two backup layers:

- Omada UI automatic backups for application-level recovery.
- `make backup` for authenticated MongoDB disaster-recovery dumps.

Before upgrading Omada:

1. Read TP-Link release notes.
2. Export an Omada UI backup.
3. Run `make backup`.
4. Update `OMADA_VERSION`, `OMADA_URL`, and `OMADA_SHA256`.
5. Rebuild with `make build`.
6. Start with `make up`.
7. Verify login, sites, devices, adoption state, and logs.

See [backup-restore.md](docs/backup-restore.md) and [upgrades.md](docs/upgrades.md).

## Supported Scope

- Clean Omada v6 installs.
- Docker Compose v2.
- MongoDB 8.0.
- `linux/amd64`.
- Local source builds from explicit TP-Link artifact URLs or staged artifacts.

## Intentionally Unsupported

- Prebuilt public controller images.
- `latest` controller tags.
- Embedded MongoDB inside the controller container.
- Legacy v3/v4/v5 upgrade logic in the entrypoint.
- ARMv7.
- Automatic major-version upgrades.
- Exposing MongoDB to the LAN by default.

## Documentation

- [bootstrap.md](bootstrap.md): design record and implementation plan.
- [docs/networking.md](docs/networking.md): host, bridge, and macvlan tradeoffs.
- [docs/adoption.md](docs/adoption.md): Omada device adoption workflows.
- [docs/configuration.md](docs/configuration.md): supported environment variables.
- [docs/backup-restore.md](docs/backup-restore.md): backup and restore runbooks.
- [docs/upgrades.md](docs/upgrades.md): safe Omada upgrade process.
- [docs/recovery.md](docs/recovery.md): recovery and downgrade guard notes.
- [docs/security.md](docs/security.md): security defaults and limitations.
- [docs/migration.md](docs/migration.md): migration notes from retired or all-in-one images.

## License

Repository packaging code is MIT licensed. TP-Link Omada Software Controller is proprietary software and must be downloaded from TP-Link by the user or builder.
