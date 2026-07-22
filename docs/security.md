# Security

Default security posture:

- Controller runs as non-root UID/GID `508`.
- MongoDB is separate and authenticated.
- MongoDB is not exposed with a host port in host mode.
- No default real passwords are committed.
- TLS certificate mount is read-only.
- Controller uses `no-new-privileges:true`.
- Docker logs are rotated.

Operational guidance:

- Use strong unique MongoDB passwords.
- Keep `.env` private.
- Keep backup archives private.
- Mount TLS certificates read-only under `certs/`.
- Keep MongoDB off host `ports:` mappings unless you have explicit firewall rules.

Limitations:

- TP-Link Omada is proprietary software and is not audited here.
- Local host processes with access to Docker bridge routes may be able to reach MongoDB on its private container address.
- Public image signing and SBOM publication are not part of the local source-build workflow.

Use strong passwords and keep backups protected.
