# Security

Default security posture:

- Controller runs as non-root UID/GID `508`.
- MongoDB is separate and authenticated.
- MongoDB is not exposed to the LAN in host mode.
- No default real passwords are committed.
- TLS certificate mount is read-only.
- Controller uses `no-new-privileges:true`.
- Docker logs are rotated.

Operational guidance:

- Use strong unique MongoDB passwords.
- Keep `.env` private.
- Keep backup archives private.
- Mount TLS certificates read-only under `certs/`.
- Keep MongoDB bound to `127.0.0.1` in host mode unless you have explicit firewall rules.

Limitations:

- TP-Link Omada is proprietary software and is not audited here.
- Local host processes can reach MongoDB on `127.0.0.1:27017`.
- Public image signing and SBOM publication are not part of the local source-build workflow.

Use strong passwords and keep backups protected.
