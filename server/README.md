# VoxMatrix - Self-Hosted Matrix Server

A complete, production-ready Matrix homeserver setup using Docker Compose. VoxMatrix provides a secure, federated messaging platform with VoIP support, automatic TLS, and easy deployment.

## Features

- **Matrix Homeserver**: Dendrite (lightweight, efficient Matrix implementation)
- **Database**: PostgreSQL for reliable data storage
- **VoIP Support**: Coturn TURN/STUN server for voice and video calls
- **Automatic TLS**: Caddy reverse proxy with Let's Encrypt certificates
- **Easy Management**: Setup, start, stop, backup, and restore scripts
- **Production Ready**: Security hardened with proper configurations

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                      Caddy (443/80)                         │
│              Reverse Proxy + Auto-TLS                        │
└────────────────────────────┬────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌────────▼────────┐  ┌───────▼────────┐
│   Dendrite     │  │   Coturn        │  │   PostgreSQL   │
│   (8008/8448)  │  │   (3478/5349)   │  │   (5432)       │
└────────────────┘  └─────────────────┘  └────────────────┘
```

## Prerequisites

- **Docker**: 20.10 or higher
- **Docker Compose**: 2.0 or higher
- **Domain Name**: A public domain with DNS configured
- **Server Ports**: 80, 443, 8008, 8448, 3478, 5349, 5432 must be available
- **Public IP**: Static or dynamic with DDNS

## Quick Start

### 1. Clone or Download

```bash
cd /home/xaf/Desktop/VoxMatrix/server
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your settings
nano .env
```

**Required changes in `.env`:**

```bash
SERVER_NAME=matrix.yourdomain.com    # Your Matrix domain
SERVER_IP=123.456.789.0              # Your public IP
POSTGRES_PASSWORD=secure_password    # Generate a strong password
TURN_USERNAME=turnuser               # TURN username
TURN_PASSWORD=secure_turn_password   # Generate a strong password
CADDY_EMAIL=admin@yourdomain.com     # For Let's Encrypt
```

### 3. Configure DNS

Add these DNS records to your domain:

```
# A record for Matrix domain
matrix.yourdomain.com    A    123.456.789.0

# SRV record for federation (optional but recommended)
_matrix._tcp.matrix.yourdomain.com    SRV    10 0 8448 matrix.yourdomain.com
```

### 4. Run Setup

```bash
chmod +x *.sh
./setup.sh
```

### 5. Start Services

```bash
./start.sh
```

### 6. Create Admin User

```bash
docker-compose exec dendrite /create-account
```

Follow the prompts to create an admin account.

## Configuration Files

### docker-compose.yml

Defines all services and their relationships:

| Service | Port | Description |
|---------|------|-------------|
| caddy | 80, 443 | Reverse proxy with TLS |
| dendrite | 8008, 8448 | Matrix homeserver |
| coturn | 3478, 5349 | TURN/STUN server |
| postgres | 5432 | Database |

### dendrite.yaml

Main Matrix server configuration:

- **Database**: PostgreSQL connection
- **TURN Server**: VoIP call configuration
- **Media**: File upload settings
- **Federation**: Inter-server communication
- **Rate Limiting**: Anti-abuse protection

### coturn/turnserver.conf

TURN server for WebRTC calls:

- **Authentication**: Username/password
- **Ports**: Relay ports for media
- **TLS**: Secure transport
- **Security**: Access controls

### Caddyfile

Reverse proxy configuration:

- **Auto-TLS**: Let's Encrypt certificates
- **Routing**: Matrix API paths
- **Security Headers**: HSTS, XSS protection
- **Logging**: Access and federation logs

## Management Scripts

### setup.sh

Initial setup script that:

- Creates directory structure
- Generates Matrix private key
- Creates secure passwords
- Sets proper permissions
- Validates configuration

```bash
./setup.sh
```

### start.sh

Starts all services:

```bash
./start.sh
```

Features:
- Pulls latest images
- Checks service health
- Displays access URLs
- Shows service status

### stop.sh

Stops all services:

```bash
./stop.sh
```

### backup.sh

Creates complete backups:

```bash
./backup.sh
```

Backs up:
- PostgreSQL database
- Dendrite configuration
- Media files
- Matrix private key
- TLS certificates

Stored in: `./backups/`

### restore.sh

Restores from backup:

```bash
./restore.sh <backup_name>
```

Example:
```bash
./restore.sh voxmatrix_backup_20240131_120000
```

## Port Mappings

| External Port | Internal Port | Service | Protocol | Purpose |
|---------------|---------------|---------|----------|---------|
| 80 | 80 | Caddy | TCP | HTTP (ACME challenge) |
| 443 | 443 | Caddy | TCP | HTTPS (Client API) |
| 8008 | 8008 | Dendrite | TCP | Client API (direct) |
| 8448 | 8448 | Dendrite | TCP | Federation API |
| 3478 | 3478 | Coturn | TCP/UDP | STUN/TURN |
| 5349 | 5349 | Coturn | TCP/UDP | STUN/TURN over TLS |
| 49152-49200 | 49152-49200 | Coturn | UDP | TURN relay |
| 5432 | 5432 | PostgreSQL | TCP | Database |

## Client Configuration

### Element Web

Access your server at: `https://matrix.yourdomain.com`

**Homeserver URL**: `https://matrix.yourdomain.com`

### Other Clients

Most Matrix clients need:
- **Homeserver URL**: `https://matrix.yourdomain.com/_matrix/client`
- **Identity Server**: (optional, leave blank)
- **Custom server**: Toggle and enter homeserver URL

## Troubleshooting

### Services Won't Start

**Check port conflicts:**
```bash
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :8008
```

**Check Docker logs:**
```bash
docker-compose logs dendrite
docker-compose logs postgres
docker-compose logs caddy
```

### TLS Certificate Issues

**Check Caddy logs:**
```bash
docker-compose logs -f caddy
```

**Verify DNS:**
```bash
dig matrix.yourdomain.com
```

**Check port 80 accessibility:**
```bash
curl http://matrix.yourdomain.com
```

### TURN Server Not Working

**Test TURN server:**
```bash
turnutils_uclient -v -u turnuser -w password matrix.yourdomain.com
```

**Check Coturn logs:**
```bash
docker-compose logs coturn
```

**Verify external IP:**
Ensure `SERVER_IP` in `.env` matches your public IP.

### Database Connection Issues

**Check PostgreSQL health:**
```bash
docker-compose exec postgres pg_isready -U dendrite
```

**Reset database (CAUTION: deletes data):**
```bash
docker-compose down -v
docker-compose up -d postgres
```

### Federation Not Working

**Check federation port:**
```bash
curl https://matrix.yourdomain.com:8448/_matrix/federation/v1/version
```

**Verify SRV records:**
```bash
dig _matrix._tcp.matrix.yourdomain.com SRV
```

**Test federation:**
```bash
# Check if other servers can reach you
curl -X GET https://matrix.org/_matrix/federation/v1/version
```

### View All Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f dendrite
docker-compose logs -f caddy

# Last 100 lines
docker-compose logs --tail=100
```

## Security Recommendations

1. **Firewall Configuration**
```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Matrix ports
sudo ufw allow 8008/tcp  # Optional (if accessing directly)
sudo ufw allow 8448/tcp  # Federation

# Allow TURN ports
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw allow 5349/udp
sudo ufw allow 49152:49200/udp

# Deny database from external
sudo ufw deny 5432/tcp
```

2. **Password Security**
   - Use strong, unique passwords in `.env`
   - Rotate passwords regularly
   - Never commit `.env` to version control

3. **TLS Configuration**
   - Caddy automatically manages Let's Encrypt certificates
   - Certificates stored in `data/caddy`
   - Back up certificates with `backup.sh`

4. **Rate Limiting**
   - Dendrite includes built-in rate limiting
   - Adjust in `dendrite.yaml` if needed
   - Consider reverse proxy rate limiting

5. **Regular Backups**
   - Run `./backup.sh` regularly
   - Set up automated cron jobs
   - Test restore procedure

6. **Monitoring**
   - Monitor logs for suspicious activity
   - Track resource usage
   - Set up alerts for service failures

## Maintenance

### Regular Tasks

**Weekly:**
```bash
# Check logs
docker-compose logs --tail=100

# Create backup
./backup.sh

# Update images
docker-compose pull
docker-compose up -d
```

**Monthly:**
```bash
# Clean old backups
ls -lt backups/ | tail -n +11 | xargs rm

# Review security updates
docker-compose pull
```

### Updates

**Update all services:**
```bash
# Stop services
./stop.sh

# Pull latest images
docker-compose pull

# Start services
./start.sh

# Verify status
docker-compose ps
```

**Update specific service:**
```bash
docker-compose pull dendrite
docker-compose up -d dendrite
```

### Resource Management

**Check disk usage:**
```bash
du -sh data/*
```

**Clean Docker resources:**
```bash
docker system prune -a
```

**View resource usage:**
```bash
docker stats
```

## Performance Tuning

### PostgreSQL

Edit in `docker-compose.yml`:
```yaml
postgres:
  command:
    - postgres
    - -c
    - shared_buffers=256MB
    - -c
    - max_connections=200
```

### Dendrite

Adjust in `dendrite.yaml`:
```yaml
database:
  max_open_conns: 90
  max_idle_conns: 5
```

### Caddy

Adjust in `Caddyfile`:
```
{
    servers {
        protocols h1 h2 h3
    }
}
```

## Federation

To enable federation with other Matrix servers:

1. **Configure DNS** (see above)
2. **Open port 8448** in firewall
3. **Verify federation**:
```bash
curl https://matrix.yourdomain.com:8448/_matrix/federation/v1/version
```

4. **Test federation**:
   - Join rooms on other servers
   - Invite users from other servers
   - Check federation tester: `https://federation-tester.matrix.org/`

## Support and Resources

- **Matrix Documentation**: https://matrix.org/docs/
- **Dendrite Documentation**: https://matrix-org.github.io/dendrite/
- **Element Web**: https://element.io/
- **Matrix Spec**: https://spec.matrix.org/

## License

This setup is provided as-is for self-hosted Matrix deployments.

## Contributing

Contributions welcome! Please feel free to submit issues or pull requests.

---

**VoxMatrix** - Your own private, secure Matrix server.
