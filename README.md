# MacReplay v2 (Test Build)

MacReplay v2 is a lightweight IPTV portal proxy packaged for Docker on Unraid. This repository exists purely as a test sandbox, so expect limited polish and no formal support.

## Snapshot

- Multi-portal management with MAC rotation and basic EPG ingestion
- Channel editor with duplicate cleanup, fallback chains, and quick filters
- Single web UI on port `8001` that exposes dashboard, portals, editor, and settings views
- Generates M3U and XMLTV outputs for Plex or any M3U-compatible player

## Quick Start on Unraid

```bash
cd /mnt/user/appdata
git clone https://github.com/T4s3rF4c3/macreplay_v2.git macreplay
cd macreplay
docker-compose -f docker-compose-unraid.yml up -d --build
```

Then open `http://YOUR-UNRAID-IP:8001` and add your first portal.

## Minimal Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| Ports | `8001/tcp` | Web dashboard + API |
| Volumes | `/mnt/user/appdata/macreplay/data:/app/data`<br>`/mnt/user/appdata/macreplay/logs:/app/logs` | Persist config and logs |
| Env Vars | `PUID=99`, `PGID=100`, `TZ=Europe/Berlin` (adjust as needed) | Match your Unraid user/group |

## Daily Use

1. **Portals tab** – add the IPTV endpoint, supply one or more MAC addresses, and verify connectivity.
2. **Editor tab** – filter channels, toggle enablement, and define fallback lists.
3. **Integrations** – consume `http://YOUR-IP:8001/playlist.m3u8` for streams and `http://YOUR-IP:8001/epg.xml` for guide data.

## Maintenance Cheatsheet

```bash
# Tail logs
docker logs macreplay -f

# Update test container
cd /mnt/user/appdata/macreplay
docker-compose -f docker-compose-unraid.yml down
git pull
docker-compose -f docker-compose-unraid.yml up -d --build

# Reset configuration
docker stop macreplay
rm /mnt/user/appdata/macreplay/data/MacReplay.json
docker start macreplay
```

## Status

Experimental test project. Use at your own risk and do not rely on it for production IPTV workloads.