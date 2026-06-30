ARG BASE_IMAGE=eclipse-temurin:17-jre-jammy
FROM ${BASE_IMAGE}

ARG OMADA_VERSION=6.2.10.17
ARG OMADA_URL
ARG OMADA_SHA256
ARG OMADA_ARTIFACT_PATH
ARG OMADA_UID=508
ARG OMADA_GID=508

LABEL org.opencontainers.image.title="Omada Controller Compose"
LABEL org.opencontainers.image.description="Controller-only TP-Link Omada Software Controller image"
LABEL org.opencontainers.image.version="${OMADA_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/maxya/omada-controller"
LABEL org.opencontainers.image.licenses="MIT"

ENV OMADA_HOME=/opt/omada
ENV TZ=Etc/UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    fontconfig \
    libfontconfig1 \
    libharfbuzz0b \
    openssl \
    tini \
    tzdata \
  && groupadd --gid "${OMADA_GID}" omada \
  && useradd --uid "${OMADA_UID}" --gid "${OMADA_GID}" --home-dir "${OMADA_HOME}" --shell /usr/sbin/nologin omada \
  && mkdir -p "${OMADA_HOME}" /tmp/omada-artifacts \
  && rm -rf /var/lib/apt/lists/*

COPY artifacts/ /tmp/omada-artifacts/
COPY docker/install-omada.sh /usr/local/bin/install-omada.sh

RUN chmod 0755 /usr/local/bin/install-omada.sh \
  && OMADA_VERSION="${OMADA_VERSION}" \
    OMADA_URL="${OMADA_URL}" \
    OMADA_SHA256="${OMADA_SHA256}" \
    OMADA_ARTIFACT_PATH="${OMADA_ARTIFACT_PATH}" \
    /usr/local/bin/install-omada.sh \
  && chown -R omada:omada "${OMADA_HOME}" \
  && chmod -R u+rwX,g+rX,o-rwx "${OMADA_HOME}" \
  && rm -rf /tmp/omada-* /usr/local/bin/install-omada.sh

COPY docker/entrypoint.sh docker/healthcheck.sh docker/import-cert.sh docker/render-properties.sh docker/version-guard.sh /usr/local/bin/

RUN chmod 0755 /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh /usr/local/bin/import-cert.sh /usr/local/bin/render-properties.sh /usr/local/bin/version-guard.sh

WORKDIR /opt/omada/lib

EXPOSE 8088 8043 8843 19810/udp 27001/udp 29810/udp 29811 29812 29813 29814 29815 29816 29817
VOLUME ["/opt/omada/data", "/opt/omada/logs"]
HEALTHCHECK --start-period=5m --interval=30s --timeout=5s --retries=5 CMD ["/usr/local/bin/healthcheck.sh"]

USER omada
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
