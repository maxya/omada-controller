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
- `OMADA_MANAGE_HTTPS_PORT`: login/management HTTPS port.

## Artifact Settings

Set `OMADA_URL` to the official TP-Link Omada Software Controller Linux `.tar.gz` download. Set `OMADA_SHA256` when you have a trusted checksum. For offline builds, place the artifact in `artifacts/` and set `OMADA_ARTIFACT_PATH`.

## Runtime Settings

The Compose files set `OMADA_MONGODB_URI` for normal deployments. Change it only when using a separately managed MongoDB instance.

Java heap settings are controlled by `JAVA_MIN_HEAP` and `JAVA_MAX_HEAP`. MongoDB memory use is controlled separately by `MONGO_CACHE_GB`.

## Port Settings

Host mode uses the host network, so configured Omada ports must be available on the Docker host. Bridge mode publishes the standard Omada ports from the container to the host.
