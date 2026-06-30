# Omada Backup And Restore

Use two backup layers:

- Omada UI automatic backups for application-level recovery.
- Authenticated MongoDB dumps for disaster recovery.

## Backup

`make backup` stops the Omada controller, runs `mongodump` with the dedicated MongoDB backup user, restarts the controller, and retains the newest `BACKUP_RETENTION_COUNT` dump directories.

Backups are written under:

```text
backups/mongodb/<timestamp>/
```

The default flow intentionally stops the controller to avoid dumping while Omada is writing.

Before upgrades or major configuration changes, also export a backup from the Omada UI. The UI backup is the easiest way to restore sites, devices, and controller configuration into a clean install.

## Restore

1. Stop the stack: `make down`.
2. Preserve current volumes before replacing data.
3. Start MongoDB only or use a temporary restore container.
4. Run `mongorestore` with the desired dump.
5. Start the full stack.
6. Verify login, devices, sites, and logs.

For migrations from other images, prefer Omada UI backup/restore first.

## Restore Drill

Do not wait for an outage to test recovery. After the first successful deployment, create a backup, restore it into a temporary clean stack, and verify that the controller login, sites, and device inventory are present.

## Password Rotation

MongoDB image init variables only apply to empty `/data/db`. Changing `.env` after first boot does not update existing users.

Use:

```sh
make rotate-mongo-password USER=omada NEW_PASSWORD='new-secret'
make rotate-mongo-password USER=omada_backup NEW_PASSWORD='new-backup-secret'
```
