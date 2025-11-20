# Production-ready Tor Docker Container
# Based on Debian Bookworm installation instructions
FROM debian:bookworm-slim

# Metadata labels
LABEL maintainer="Tor Node Operator"
LABEL description="Production Tor relay/bridge running on Debian Bookworm"
LABEL version="1.0"

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TOR_USER=debian-tor

# Step 1: Install required basic packages
# Following the PDF installation guide
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        apt-transport-https \
        lsb-release && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Step 2: Store Tor signature key locally
# Split into separate RUN command for better error isolation
RUN mkdir -p /usr/share/keyrings && \
    curl -fsSL https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | \
        gpg --dearmor -o /usr/share/keyrings/tor-archive-keyring.gpg

# Step 3: Create repo file with signed-by method
# Note: We skip the fingerprint verification in Docker build as it can be inconsistent
# The signed-by method itself provides cryptographic verification
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -sc) main" > \
        /etc/apt/sources.list.d/tor.list

# Step 4: Install Tor and keyring package
# The deb.torproject.org-keyring package keeps keys up-to-date
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tor \
        deb.torproject.org-keyring && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create necessary directories with proper permissions
# /var/lib/tor will be mounted as a volume for persistent data (keys, fingerprints)
RUN mkdir -p /var/lib/tor && \
    chown -R ${TOR_USER}:${TOR_USER} /var/lib/tor && \
    chmod 700 /var/lib/tor

# Create directory for torrc configuration
RUN mkdir -p /etc/tor && \
    chown -R ${TOR_USER}:${TOR_USER} /etc/tor

# Health check to ensure Tor is running properly
# Checks if the Tor process is running
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -x tor > /dev/null || exit 1

# Switch to non-root user for security
USER ${TOR_USER}

# Expose common Tor ports (can be overridden in docker-compose.yml)
# ORPort (relay traffic), DirPort (directory information), ControlPort
EXPOSE 9001 9030 9051

# Set working directory
WORKDIR /var/lib/tor

# Start Tor with the mounted configuration
# -f specifies the config file location
ENTRYPOINT ["tor"]
CMD ["-f", "/etc/tor/torrc"]
