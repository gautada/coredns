ARG CONTAINER_VERSION=13.3

# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ STAGE 1: Build CoreDNS from source                                       │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM golang:1.25-trixie AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl git jq \
 && rm -rf /var/lib/apt/lists/*

# Resolve the latest CoreDNS release tag and clone at that version.
RUN COREDNS_VERSION=$(curl -sL "https://api.github.com/repos/coredns/coredns/releases/latest" \
      | jq -r '.tag_name' \
      | tr -d '[:space:]') \
 && { [ -n "$COREDNS_VERSION" ] && [ "$COREDNS_VERSION" != "null" ] \
      || { echo "ERROR: failed to resolve latest CoreDNS release from GitHub API" >&2; exit 1; }; } \
 && echo "Building CoreDNS ${COREDNS_VERSION}" \
 && git config --global advice.detachedHead false \
 && git clone --branch "$COREDNS_VERSION" --depth 1 https://github.com/coredns/coredns.git /coredns

WORKDIR /coredns
RUN go generate && go build -o coredns .

# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ STAGE 2: Final container image                                           │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM docker.io/gautada/debian:${CONTAINER_VERSION} AS container

ARG IMAGE_NAME=coredns

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A CoreDNS container based on gautada/debian."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.source="https://github.com/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.license="Apache-2.0"

# ╭――――――――――――――――――――╮
# │ PACKAGES           │
# ╰――――――――――――――――――――╯
RUN apt-get update \
 && apt-get install -y --no-install-recommends jq libcap2-bin \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG USER=coredns
RUN /usr/sbin/usermod -l $USER debian \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER debian \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
COPY --from=builder /coredns/coredns /usr/bin/coredns
RUN /sbin/setcap cap_net_bind_service=+ep /usr/bin/coredns

# Corefile and zone files are supplied via k8s configmap volume mounts.
RUN mkdir -p /etc/container/configmaps /mnt/volumes/configmaps \
 && ln -fsv /mnt/volumes/configmaps/Corefile    /etc/container/Corefile \
 && ln -fsv /mnt/volumes/configmaps/zone.local  /etc/container/zone.local \
 && ln -fsv /mnt/volumes/configmaps/zone.tld    /etc/container/zone.tld

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
COPY version.sh /usr/bin/container-version
RUN chmod +x /usr/bin/container-version

# ╭――――――――――――――――――――╮
# │ LATEST             │
# ╰――――――――――――――――――――╯
COPY latest.sh /usr/bin/container-latest
RUN chmod +x /usr/bin/container-latest

# ╭――――――――――――――――――――╮
# │ IMGVERSION         │
# ╰――――――――――――――――――――╯
COPY imgversion.sh /usr/bin/container-imgversion
RUN chmod +x /usr/bin/container-imgversion

# ╭――――――――――――――――――――╮
# │ HEALTH             │
# ╰――――――――――――――――――――╯
COPY appversion-check.sh /etc/container/health.d/appversion-check
RUN chmod +x /etc/container/health.d/appversion-check
# COPY imgversion.sh /etc/container/health.d/imgversion-check
# RUN chmod +x /etc/container/health.d/imgversion-check
COPY coredns-running.sh /etc/container/health.d/coredns-running
RUN chmod +x /etc/container/health.d/coredns-running

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY coredns.s6 /etc/services.d/coredns/run
RUN chmod +x /etc/services.d/coredns/run

VOLUME /mnt/volumes/configmaps
EXPOSE 53/tcp
EXPOSE 53/udp
EXPOSE 8080/tcp
EXPOSE 9153/tcp

WORKDIR /home/${USER}
