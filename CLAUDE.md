# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

periodic-s3-sync is a Docker image that syncs files between S3-compatible object stores and local paths, either once at startup or on a cron schedule. It uses s3cmd for sync operations and supports AWS S3, DigitalOcean Spaces, MinIO, and other S3-compatible stores.

## Build Commands

```bash
# Build the Docker image locally
docker build -t periodic-s3-sync .

# Run the container
docker run -d \
    -e SYNC_FROM=s3://bucket/path/ \
    -e SYNC_TO=/data \
    -e AWS_ACCESS_KEY_ID=xxx \
    -e AWS_SECRET_ACCESS_KEY=xxx \
    periodic-s3-sync
```

## Architecture

The project consists of two shell scripts:

- **entrypoint.sh** - Container entrypoint that parses SYNC_MODE and either runs an immediate sync, sets up cron, or both
- **s3-sync.sh** - Core sync logic using s3cmd; handles endpoint configuration, chown/chmod, and completion file creation

## Key Environment Variables

- `AWS_ENDPOINT_URL` - Custom endpoint for non-AWS S3-compatible stores (e.g., `nyc3.digitaloceanspaces.com`)
- `SYNC_MODE` - `STARTUP`, `PERIODIC`, or `STARTUP+PERIODIC`
- `COMPLETION_FILENAME` - If set, this file is touched after sync and excluded from future syncs

## CI/CD

GitHub Actions workflow builds multi-arch images (amd64/arm64) and pushes to ghcr.io. Build numbers are recorded via a reusable workflow from zostay/build.
