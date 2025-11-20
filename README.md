# Production Tor Docker Container

This Docker setup provides a production-ready Tor relay/bridge container based on Debian Bookworm, following the official Tor Project installation guidelines.

## Features

- **Official Tor Repository**: Uses the official Tor Project repository with GPG signature verification
- **Debian Bookworm Slim**: Minimal base image for reduced attack surface
- **Persistent Storage**: Keys and fingerprints stored in volumes for relay migration
- **Security Hardened**: No-new-privileges, AppArmor, dropped capabilities, read-only root filesystem
- **Host Network Mode**: Direct host network access for optimal performance
- **Structured Logging**: JSON logging with rotation (10MB max, 5 files)
- **Health Checks**: Automatic monitoring of Tor process
- **Resource Limits**: Configurable CPU and memory constraints

## Directory Structure

```
.
├── Dockerfile              # Container build instructions
├── docker-compose.yml      # Service orchestration
├── torrc                   # Tor configuration file (create this)
├── tor-data/              # Persistent data directory (auto-created)
│   ├── keys/              # Relay identity keys
│   ├── fingerprint        # Relay fingerprint
│   └── state              # Tor state information
└── README.md              # This file
```

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 1.29+
- Sufficient bandwidth for running a Tor relay
- Open firewall ports (9001, 9030 by default)

## Setup Instructions

### 1. Create Configuration File

Create a `torrc` file in the project directory:

```bash
cp torrc.sample torrc
nano torrc
```

Edit the configuration according to your needs. **Important settings to change:**
- `Nickname`: Your relay's name
- `ContactInfo`: Your contact email
- `RelayBandwidthRate`: Your bandwidth commitment
- `ORPort` and `DirPort`: Ensure these match your firewall rules

### 2. Create Data Directory

```bash
mkdir -p tor-data
chmod 700 tor-data
```

**Note**: The container runs as the `debian-tor` user (UID 114 typically). You may need to adjust ownership:

```bash
sudo chown -R 114:114 tor-data
```

### 3. Configure Firewall

If using UFW (as mentioned in the installation PDF):

```bash
sudo ufw allow 9001/tcp  # ORPort
sudo ufw allow 9030/tcp  # DirPort
sudo ufw reload
```

For other firewalls, ensure the ports specified in your `torrc` are open.

### 4. Build and Start

```bash
# Build the container
docker-compose build

# Start in detached mode
docker-compose up -d

# View logs
docker-compose logs -f tor
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
   sudo chown -R 114:114 tor-data
   ```

3. **Copy your torrc configuration**:
   ```bash
   sudo cp /etc/tor/torrc ./torrc
   ```

4. **Start the container**:
   ```bash
   docker-compose up -d
   ```

Your relay will maintain its identity and reputation in the Tor network.

## Monitoring

### View Logs
```bash
docker-compose logs -f tor
```

### Check Container Status
```bash
docker-compose ps
```

### Check Relay Status
After your relay has been running for a few hours, check its status:
- Relay Search: https://metrics.torproject.org/rs.html
- Search by nickname or fingerprint (found in `tor-data/fingerprint`)

### Resource Usage
```bash
docker stats tor-relay
```

## Maintenance

### Update Tor
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

The `deb.torproject.org-keyring` package ensures the GPG keys stay up-to-date automatically.

### Backup Relay Identity
```bash
tar -czf tor-backup-$(date +%Y%m%d).tar.gz tor-data/
```

### Restart Container
```bash
docker-compose restart tor
```

## Security Considerations

1. **Read-only Root Filesystem**: The container's root filesystem is read-only, preventing unauthorized modifications
2. **Dropped Capabilities**: All Linux capabilities are dropped for minimal privilege
3. **AppArmor**: Default Docker AppArmor profile is enforced
4. **No New Privileges**: Prevents privilege escalation
5. **Resource Limits**: CPU and memory limits prevent resource exhaustion
6. **Non-root User**: Container runs as `debian-tor` user

## Troubleshooting

### Permission Errors
If you see permission errors for `/var/lib/tor`:
```bash
sudo chown -R 114:114 tor-data
chmod 700 tor-data
```

### Port Binding Errors
Ensure no other service is using the Tor ports:
```bash
sudo netstat -tulpn | grep -E ':(9001|9030|9051)'
```

### Configuration Errors
Validate your torrc before starting:
```bash
docker-compose run --rm tor --verify-config -f /etc/tor/torrc
```

### Container Won't Start
Check logs for details:
```bash
docker-compose logs tor
```

## Performance Tuning

For high-bandwidth relays, adjust in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 4G
      cpus: '4.0'
```

And in your `torrc`:
```
RelayBandwidthRate 50 MBytes
RelayBandwidthBurst 100 MBytes
```

## References

- Official Tor Project: https://www.torproject.org/
- Tor Relay Guide: https://community.torproject.org/relay/
- Debian Repository: https://deb.torproject.org/
- Metrics Portal: https://metrics.torproject.org/

## License

This Docker configuration is provided as-is for running Tor relays. Tor itself is licensed under the 3-clause BSD license.

## Support

For Tor-specific questions, consult:
- Tor Project Documentation: https://support.torproject.org/
- Tor Relay Mailing List: tor-relays@lists.torproject.org
