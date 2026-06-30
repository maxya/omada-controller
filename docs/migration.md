# Migration To This Omada Docker Stack

The recommended migration path is Omada's built-in backup and restore workflow. It is easier to validate and less risky than moving raw MongoDB files between containers.

## Recommended Migration

1. Export an Omada backup from the old controller UI.
2. Start this stack cleanly.
3. Restore the Omada backup through the new controller UI.
4. Verify sites, devices, and adoption state.

This path is appropriate for migrations from retired Docker images, all-in-one Omada containers, bare-metal installs, and other Compose stacks.

## Raw MongoDB Data

Direct MongoDB data migration is not part of the standard workflow. MongoDB init scripts only run on empty data directories, and raw database moves can fail when MongoDB versions, storage formats, or Omada versions differ.

Use raw database migration only when you understand the source and destination MongoDB versions and have a tested rollback.
