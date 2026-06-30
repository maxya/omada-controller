# Omada Upgrades

Safe upgrade flow:

1. Read TP-Link release notes.
2. Confirm device firmware compatibility.
3. Export an Omada UI backup.
4. Run `make backup`.
5. Update `OMADA_VERSION`, `OMADA_URL`, and `OMADA_SHA256` in `.env`.
6. Run `make build`.
7. Run `make up`.
8. Verify login, sites, devices, adoption status, and logs.
9. Keep the previous image tag and backups until the site has run cleanly for at least 24 hours.

Do not auto-upgrade controller major versions. Watchtower is represented only as a disabled monitor-only example.

## Version Pinning

Pin `OMADA_VERSION` and use an explicit TP-Link download URL. Avoid `latest`-style workflows for the controller because Omada upgrades can change database state and device compatibility.

## After Upgrade

Verify:

- Controller login works.
- Sites and device inventory are present.
- Devices remain adopted.
- Logs do not show MongoDB authentication or migration errors.
- Automatic backups are still configured in the Omada UI.
