# Configuration

Supported environment variables are listed in `.env.example`.

Important variables:

- `OMADA_VERSION`: controller version to build and tag.
- `OMADA_URL`: official TP-Link Omada Linux `.tar.gz` artifact URL.
- `OMADA_SHA256`: optional trusted checksum.
- `OMADA_ARTIFACT_PATH`: optional staged artifact under `artifacts/`.
- `OMADA_MONGODB_URI`: set by Compose for normal use.
- `JAVA_MIN_HEAP` and `JAVA_MAX_HEAP`: used by the entrypoint to build the Java command.
- `MONGO_CACHE_GB`: WiredTiger cache cap.
- `MONGO_IMAGE`: MongoDB image tag, default `mongo:8.2`.

### MongoDB and Linux kernel 6.19+

`mongo:8.0` and `mongo:8.3` refuse to start on Linux kernel 6.19 and newer, exiting with
`MongoDB cannot start: Linux kernel versions 6.19 and newer has a known incompatibility`.
The cause is the bundled TCMalloc violating the kernel rseq ABI
(<https://jira.mongodb.org/browse/SERVER-121912>); MongoDB added a hard startup check.

Verified on kernel 7.1.4: `mongo:8.2.11` and `mongo:7.0.37` start and pass the healthcheck,
`mongo:8.0` and `mongo:8.3` do not. The default is therefore `mongo:8.2`.

Note that `8.2` is a minor release, so it stops receiving patches once a later minor ships.
Once MongoDB relaxes the check on the `8.0` LTS line (<https://jira.mongodb.org/browse/SERVER-125742>
removes it for kernel 7.0.14+), moving back to `8.0` requires a dump and restore, because MongoDB
data files cannot be downgraded across major versions.
- `OMADA_MANAGE_HTTPS_PORT`: login/management HTTPS port.

## Artifact Settings

Set `OMADA_URL` to the official TP-Link Omada Software Controller Linux `.tar.gz` download. Set `OMADA_SHA256` when you have a trusted checksum. For offline builds, place the artifact in `artifacts/` and set `OMADA_ARTIFACT_PATH`.

## Runtime Settings

The Compose files set `OMADA_MONGODB_URI` for normal deployments. Change it only when using a separately managed MongoDB instance.

Java heap settings are controlled by `JAVA_MIN_HEAP` and `JAVA_MAX_HEAP`. MongoDB memory use is controlled separately by `MONGO_CACHE_GB`.

## Port Settings

Host mode uses the host network, so configured Omada ports must be available on the Docker host. Bridge mode publishes the standard Omada ports from the container to the host.
