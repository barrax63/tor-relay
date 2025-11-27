# =============================================================================
# Tor Relay/Bridge - Privacy Network Node
# =============================================================================
# Production-ready Tor relay based on official Tor Project packages
# =============================================================================

FROM debian:bookworm-slim

# OCI Image Specification Labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="tor-relay" \
      org.opencontainers.image.description="Production Tor relay/bridge node running on Debian Bookworm" \
      org.opencontainers.image.authors="Noah Nowak <nnowak@cryshell.com>" \
      org.opencontainers.image.url="https://github.com/barrax63/tor-relay" \
      org.opencontainers.image.source="https://github.com/barrax63/tor-relay" \
      org.opencontainers.image.documentation="https://github.com/barrax63/tor-relay/blob/main/README.md" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="docker.io/library/debian:bookworm-slim"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TOR_USER=debian-tor

# Install prerequisites for adding Tor repository
RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Add official Tor Project signing key
RUN mkdir -p /usr/share/keyrings && \
    curl -fsSL https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | \
        gpg --dearmor -o /usr/share/keyrings/tor-archive-keyring.gpg

# Configure official Tor Project repository
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] \
    https://deb.torproject.org/torproject.org $(lsb_release -sc) main" > \
    /etc/apt/sources.list.d/tor.list

# Install Tor from official repository
RUN apt-get update && apt-get install -y --no-install-recommends \
        tor \
        deb.torproject.org-keyring \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup directories with proper permissions
RUN mkdir -p /var/lib/tor /etc/tor && \
    chown -R ${TOR_USER}:${TOR_USER} /var/lib/tor /etc/tor && \
    chmod 700 /var/lib/tor

WORKDIR /var/lib/tor

# Health check - verify Tor control port or process
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://127.0.0.1:9120/metrics || exit 1

# Run as non-root user
USER ${TOR_USER}

# ORPort (relay traffic), DirPort (directory information)
EXPOSE 9001 9030

ENTRYPOINT ["tor"]
CMD ["-f", "/etc/tor/torrc"]
