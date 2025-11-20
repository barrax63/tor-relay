#!/bin/bash
# Tor Docker Setup Script
# This script prepares the environment for running Tor in Docker

set -e

echo "Setting up Tor Docker environment..."

# Check if tor-data exists and has wrong ownership
if [ -d "./tor-data" ]; then
    CURRENT_OWNER=$(stat -c '%U' ./tor-data 2>/dev/null || stat -f '%Su' ./tor-data 2>/dev/null)
    echo "tor-data directory exists (owner: $CURRENT_OWNER)"
    
    # Check if we need to fix ownership
    if [ "$CURRENT_OWNER" != "docker" ] && [ "$CURRENT_OWNER" != "$USER" ]; then
        echo "  Directory has wrong ownership. Fixing..."
        sudo chown -R $USER:$USER ./tor-data
    fi
else
    echo "Creating tor-data directory..."
    mkdir -p ./tor-data
fi

# Get the debian-tor UID from the container
echo "Detecting debian-tor user ID from container..."
DEBIAN_TOR_UID=$(docker compose run --rm --entrypoint="" tor id -u debian-tor 2>/dev/null || echo "100")
DEBIAN_TOR_GID=$(docker compose run --rm --entrypoint="" tor id -g debian-tor 2>/dev/null || echo "100")

echo "   debian-tor UID:GID = $DEBIAN_TOR_UID:$DEBIAN_TOR_GID"

# Set proper ownership using sudo
echo "Setting ownership of tor-data to UID:GID $DEBIAN_TOR_UID:$DEBIAN_TOR_GID..."
sudo chown -R $DEBIAN_TOR_UID:$DEBIAN_TOR_GID ./tor-data

# Set proper permissions (700 for security) using sudo
echo "Setting permissions on tor-data (700)..."
sudo chmod 700 ./tor-data

# If there are files inside, set their permissions too
if [ "$(sudo ls -A ./tor-data)" ]; then
    echo "Setting permissions on files inside tor-data..."
    sudo find ./tor-data -type f -exec chmod 600 {} \;
    sudo find ./tor-data -type d -exec chmod 700 {} \;
fi

# Check if torrc exists
if [ ! -f "./torrc" ]; then
    echo "  Warning: torrc file not found!"
    if [ -f "./torrc.sample" ]; then
        echo "Copying torrc.sample to torrc..."
        cp torrc.sample torrc
        echo "  Please edit ./torrc with your relay configuration"
    else
        echo "Error: torrc.sample not found. Please create a torrc file."
        exit 1
    fi
fi

echo ""
echo "Setup complete!"
echo ""
echo "Directory ownership:"
ls -ld ./tor-data
echo ""
echo "Next steps:"
echo "  1. Verify ./torrc has your relay settings"
echo "  2. Run: docker-compose up -d"
echo "  3. Monitor logs: docker-compose logs -f tor"
echo ""
