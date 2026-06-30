# Omada Recovery

## Unclean Shutdown

The stack uses `stop_grace_period: 90s` to give Omada and MongoDB time to stop cleanly.

If MongoDB reports WiredTiger corruption after an unclean shutdown:

1. Stop the full stack.
2. Backup the current MongoDB volume before attempting repair.
3. Run a one-off MongoDB container with the same data volume and `mongod --repair`.
4. Start MongoDB and inspect logs.
5. Start the controller only after MongoDB is healthy.

Prefer restoring from a known-good backup when repair output is unclear.

## Downgrade Guard

The controller records the last started Omada version in `/opt/omada/data/.last_started_version`. Starting an older image against newer data exits non-zero.

Only remove this file after restoring from backup or intentionally accepting downgrade risk.

## Failed Upgrade

If an Omada upgrade fails:

1. Stop the stack.
2. Preserve the current volumes before making changes.
3. Review controller and MongoDB logs.
4. Restore the most recent Omada UI backup or MongoDB dump if the controller cannot start cleanly.
5. Rebuild the previous known-good Omada version if needed.

Do not repeatedly start different controller versions against the same data without a backup. Omada upgrades can change persisted state.
