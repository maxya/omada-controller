# Omada Controller Operations

## First Run

1. Copy `.env.example` to `.env`.
2. Replace all example passwords.
3. Set `OMADA_URL` and optionally `OMADA_SHA256`.
4. Run `make preflight`.
5. Run `make build`.
6. Run `make up`.
7. Open `https://<host-ip>:8043/`.
8. Enable Omada automatic backups.

Run `make smoke` after the controller starts to verify that Compose is running and the Omada login endpoint responds.

## Support Bundle

Run:

```sh
make support-bundle
```

The bundle includes redacted Compose config, logs, Docker versions, and inspect output. Raw `.env` is not included.

Review support bundles before sharing them publicly. Redaction is built in, but operational logs can still reveal hostnames, IP addresses, device names, or site names.

## Logs

Use:

```sh
make logs
```

Docker log rotation is configured in the host-mode Compose file. Omada application logs are persisted in the `omada-logs` volume.

## Routine Maintenance

- Keep Omada backups enabled in the UI.
- Run `make backup` before upgrades.
- Read TP-Link release notes before changing `OMADA_VERSION`.
- Keep previous controller images and backups until the upgraded site has run cleanly.
- Rotate MongoDB passwords with `make rotate-mongo-password`; changing `.env` alone does not update existing MongoDB users.
