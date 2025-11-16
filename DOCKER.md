# MacReplayV2 - Docker Image

[![Docker Build](https://github.com/T4s3rF4c3/macreplay_v2/actions/workflows/docker-build.yml/badge.svg)](https://github.com/T4s3rF4c3/macreplay_v2/actions/workflows/docker-build.yml)
[![GitHub release](https://img.shields.io/github/release/T4s3rF4c3/macreplay_v2.svg)](https://github.com/T4s3rF4c3/macreplay_v2/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This Docker image provides MacReplayV2 - an enhanced IPTV portal proxy with advanced channel management capabilities, optimized for Unraid deployment.

## 🚀 Quick Start

### Docker Run

```bash
docker run -d \
  --name macreplayv2 \
  -p 8001:8001 \
  -v /path/to/config:/app/config \
  -e PUID=99 \
  -e PGID=100 \
  ghcr.io/t4s3rf4c3/macreplay_v2:latest
```

### Docker Compose

```yaml
version: '3.8'

services:
  macreplayv2:
    image: ghcr.io/t4s3rf4c3/macreplay_v2:latest
  container_name: macreplayv2
    ports:
      - "8001:8001"
    volumes:
      - ./config:/app/config
    environment:
      - PUID=99
      - PGID=100
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## 📋 Available Tags

| Tag | Description | Base | Architectures |
|-----|-------------|------|---------------|
| `latest` | Latest stable release | python:3.11-slim | amd64, arm64 |
| `v2.x.x` | Specific version | python:3.11-slim | amd64, arm64 |
| `main` | Development build | python:3.11-slim | amd64, arm64 |

## 🛠️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `99` | User ID for file permissions |
| `PGID` | `100` | Group ID for file permissions |
| `PORT` | `8001` | Application port |

### Volumes

| Path | Description |
|------|-------------|
| `/app/config` | Configuration and data storage |

### Ports

| Port | Description |
|------|-------------|
| `8001` | Web interface and API |

## 🔧 Unraid Installation

1. **Add Community Applications** (if not already installed)
2. **Search for "MacReplayV2"** in Community Applications
3. **Install** and configure the template
4. **Access** the web interface at `http://your-unraid-ip:8001`

### Manual Unraid Template

Download the template from: [unraid-template.xml](https://github.com/T4s3rF4c3/macreplay_v2/raw/main/unraid-template.xml)

## 🏥 Health Check

The container includes a built-in health check:

```bash
curl -f http://localhost:8001/health
```

Returns HTTP 200 when the application is healthy.

## 🔐 Security

- Runs as non-root user (PUID/PGID)
- Minimal attack surface with slim base image
- Regular security updates
- No sensitive data in logs

## 📊 Resource Usage

**Minimum Requirements:**
- CPU: 1 core
- RAM: 256MB
- Storage: 100MB

**Recommended:**
- CPU: 2 cores
- RAM: 512MB
- Storage: 1GB

## 🐛 Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check logs
docker logs macreplayv2

# Verify permissions
ls -la /path/to/config
```

**Permission errors:**
```bash
# Fix ownership
sudo chown -R 99:100 /path/to/config
```

**Network connectivity:**
```bash
# Test health endpoint
curl -f http://localhost:8001/health

# Check container network
docker exec macreplayv2 curl -f http://localhost:8001/health
```

## 📚 Documentation

- **Main Repository:** [T4s3rF4c3/macreplay_v2](https://github.com/T4s3rF4c3/macreplay_v2)
- **Installation Guide:** [README.md](https://github.com/T4s3rF4c3/macreplay_v2/blob/main/README.md)
- **Changelog:** [CHANGELOG.md](https://github.com/T4s3rF4c3/macreplay_v2/blob/main/CHANGELOG.md)
- **Contributing:** [CONTRIBUTING.md](https://github.com/T4s3rF4c3/macreplay_v2/blob/main/CONTRIBUTING.md)

## 📞 Support

- **GitHub Issues:** [Report bugs and request features](https://github.com/T4s3rF4c3/macreplay_v2/issues)
- **GitHub Discussions:** [Community support and questions](https://github.com/T4s3rF4c3/macreplay_v2/discussions)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/T4s3rF4c3/macreplay_v2/blob/main/LICENSE) file for details.

---

**Built with ❤️ for the IPTV community**