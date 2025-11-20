# Tor Relay Docker Container

This Docker setup provides a production-ready Tor relay/bridge container based on Debian Bookworm, following the official Tor Project installation guidelines.

## Features

- **Official Tor Repository**: Uses the official Tor Project repository with GPG signature verification
- **Debian Bookworm Slim**: Minimal base image for reduced attack surface
- **Persistent Storage**: Keys and fingerprints stored in volumes for relay migration
- **Security Hardened**: No-new-privileges, AppArmor, dropped capabilities
- **Host Network Mode**: Direct host network access for optimal performance
- **Structured Logging**: JSON logging with rotation (10MB max, 5 files)
- **Health Checks**: Automatic monitoring of Tor process
- **Resource Limits**: Configurable CPU and memory constraints
- **Automatic Permission Checks**: Smart entrypoint validates permissions and configuration on every start
- **Helpful Error Messages**: Clear guidance when issues are detected

## Directory Structure

```
.
├── Dockerfile             # Container build instructions
├── docker-compose.yml     # Service orchestration
├── torrc                  # Tor configuration file (create this)
├── tor-data/              # Persistent data directory (auto-created)
│   ├── keys/              # Relay identity keys
│   ├── fingerprint        # Relay fingerprint
│   └── state              # Tor state information
├── setup.sh               # Automated setup script
└── README.md              # This file
```

## Setup Instructions

### 1. Configure Firewall

If using UFW:

```bash
sudo ufw allow 9001/tcp  # ORPort
sudo ufw allow 9030/tcp  # DirPort
sudo ufw reload
```

For other firewalls, ensure the ports specified in your `torrc` are open.

### 2. Build and Start

```bash
# 3. Build the image
docker compose build

# 2. Create configuration
nano torrc  # Edit with your settings (Nickname, ContactInfo, etc.)

# 3. Run setup script
chmod +x setup.sh
./setup.sh

# 4. Start the container
docker compose up -d

# 4. Monitor logs and automatic checks
docker compose logs -f tor
```

## Migrating an Existing Relay

To migrate an existing Tor relay to this container:

1. **Stop your existing Tor service**:
   ```bash
   sudo systemctl stop tor
   ```

2. **Copy your existing Tor data**:
   ```bash
   sudo cp -r /var/lib/tor/* ./tor-data/
   sudo chown -R 100:100 tor-data
   sudo chmod 700 tor-data
   sudo find ./tor-data -type f -exec chmod 600 {} \;
   sudo find ./tor-data -type d -exec chmod 700 {} \;
   ```

3. **Copy your torrc configuration**:
   ```bash
   sudo cp /etc/tor/torrc ./torrc
   ```

4. **Start the container**:
   ```bash
   docker compose build
   docker compose up -d
   ```

Your relay will maintain its identity and reputation in the Tor network.

## Monitoring

### View Logs
```bash
docker compose logs -f tor
```

### Check Container Status
```bash
docker compose ps
```

### Check Relay Status
After your relay has been running for a few hours, check its status:
- **Relay Search**: https://metrics.torproject.org/rs.html
- Search by nickname or fingerprint (found in `tor-data/fingerprint`)

### Resource Usage
```bash
docker stats tor
```

### View Relay Fingerprint
```bash
cat tor-data/fingerprint
```

Or check the container logs - the fingerprint is displayed on startup.

## Maintenance

### Update Tor

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

The `deb.torproject.org-keyring` package ensures the GPG keys stay up-to-date automatically.

### Backup Relay Identity

**Important**: Your relay's identity is stored in `tor-data/`. Back it up regularly!

```bash
# Create a timestamped backup
tar -czf tor-backup-$(date +%Y%m%d).tar.gz tor-data/

# Verify the backup
tar -tzf tor-backup-$(date +%Y%m%d).tar.gz
```

## Security Considerations

1. **Dropped Capabilities**: All Linux capabilities are dropped for minimal privilege
2. **AppArmor**: Default Docker AppArmor profile is enforced
3. **No New Privileges**: Prevents privilege escalation
4. **Resource Limits**: CPU and memory limits prevent resource exhaustion
5. **Non-root User**: Container runs as `debian-tor` user (UID 100)
6. **Read-only Configuration**: torrc is mounted read-only to prevent tampering
7. **Secure Permissions**: Data directory uses 700 permissions (owner-only access)
8. **Automatic Validation**: Configuration is validated before Tor starts

## References

- **Official Tor Project**: https://www.torproject.org/
- **Tor Relay Guide**: https://community.torproject.org/relay/
- **Debian Repository**: https://deb.torproject.org/
- **Metrics Portal**: https://metrics.torproject.org/
- **Relay Requirements**: https://community.torproject.org/relay/relays-requirements/
- **Tor Manual**: https://2019.www.torproject.org/docs/tor-manual.html.en

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.
