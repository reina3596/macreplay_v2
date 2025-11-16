# Changelog

All notable changes to MacReplayV2 will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-03

### Added
- **Enhanced Channel Editor**: Advanced DataTables interface with improved filtering
- **Smart Fallback System**: Automatic failover to backup channels
- **Intelligent Duplicate Detection**: Only considers enabled channels as duplicates
- **One-Click Duplicate Cleanup**: Remove duplicate enabled channels efficiently
- **Multi-Level Filtering**: Portal, Genre, and Duplicate filters work together
- **Autocomplete Fallbacks**: Smart suggestions for channel failover setup
- **Multiple MAC Support**: Rotate between MAC addresses for multiple connections
- **Improved Portal Management**: Enhanced interface for managing multiple portals
- **Real-time Channel Preview**: Play channels directly in the editor
- **Enhanced Dashboard**: Better statistics and monitoring
- **Unraid Optimization**: Specifically designed for Unraid deployment
- **Docker Health Checks**: Built-in container health monitoring
- **Resource Management**: Configurable CPU and memory limits
- **Proper User/Group Handling**: Unraid-compatible permission management

### Changed
- **Complete UI Overhaul**: Modern Bootstrap-based interface
- **Improved Performance**: Optimized channel loading and filtering
- **Better Error Handling**: More informative error messages and logging
- **Enhanced Security**: Container runs with restricted privileges
- **Streamlined Installation**: Simplified Unraid deployment process

### Fixed
- **Template Syntax Issues**: Resolved Jinja2 template errors
- **DataTables Integration**: Fixed JavaScript library conflicts
- **Docker Build Problems**: Resolved Buildx compatibility issues
- **Permission Issues**: Fixed Unraid file permission handling
- **Memory Leaks**: Improved resource cleanup

### Security
- **Container Security**: Runs with no-new-privileges flag
- **User Isolation**: Proper user/group separation
- **Log Rotation**: Prevents disk space issues from large logs

## [1.0.0] - Previous Version

### Initial Features
- Basic portal management
- Simple channel editor
- EPG support
- Dashboard interface
- Settings management

---

## Upgrade Instructions

### From v1.x to v2.0

1. **Backup your configuration:**
   ```bash
   cp /mnt/user/appdata/macreplayv2/data/MacReplayV2.json /tmp/backup/
   ```

2. **Stop the old container:**
   ```bash
   docker stop macreplayv2
   docker rm macreplayv2
   ```

3. **Pull the new version:**
   ```bash
   cd /mnt/user/appdata/macreplayv2
   git pull
   ```

4. **Start with new version:**
   ```bash
   docker-compose -f docker-compose-unraid.yml up -d --build
   ```

5. **Verify the upgrade:**
   - Check that your portals are still configured
   - Verify channels are loading correctly
   - Test the new duplicate detection features

### Note on Configuration Compatibility

MacReplayV2 is backward compatible with v1.x configuration files. Your existing portal and channel settings will be preserved during the upgrade.