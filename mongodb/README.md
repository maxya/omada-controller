# MongoDB

The default stack uses the official `mongo:8.0` image with authentication enabled. Initialization scripts under `mongodb/init/` run only when `/data/db` is empty.

Changing passwords in `.env` after first boot does not update existing MongoDB users. Use `make rotate-mongo-password USER=omada` or `USER=omada_backup` so MongoDB and local configuration are changed together.

Host-mode Compose binds MongoDB to `127.0.0.1` only. Do not expose MongoDB to the LAN unless you have a specific firewall and threat model.

