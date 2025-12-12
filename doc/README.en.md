# Neutrino Mediathek Plugin

Simple access to the community Mediathek catalog directly inside Neutrino. Works with the public API or any self-hosted backend that speaks the same interface.

## Table of Contents
- [What It Does](#what-it-does)
- [Quick Start for Users](#quick-start-for-users)
  - [Install via UI Package Manager](#install-via-ui-package-manager)
  - [Install via SSH Package Manager](#install-via-ssh-package-manager)
  - [Manual Copy / SFTP](#manual-copy--sftp)
  - [Configure the API URL](#configure-the-api-url)
- [Tips for Smooth Playback](#tips-for-smooth-playback)
- [Developer Corner](#developer-corner)
  - [Requirements](#requirements)
  - [Local Build & Update](#local-build--update)
  - [Local Backend Workflow](#local-backend-workflow)
  - [Environment Override](#environment-override)
  - [Connectivity Checks (curl & Lua)](#connectivity-checks-curl--lua)
- [Troubleshooting](#troubleshooting)
- [Backend References](#backend-references)

## What It Does
- Browses and plays Mediathek entries via the `mt-api` backend (public default: `https://mt.api.tuxbox-neutrino.org/mt-api`).
- Runs fully in Lua, no compilation on the target.
- Works with local or remote backends that implement the same REST contract.

## Quick Start for Users

### Install via UI Package Manager
If your image ships a package manager:
- Open *Service → Software Update → Package Manager*.
- Select `neutrino-mediathek`, install, then restart the GUI.

### Install via SSH Package Manager
```bash
ssh root@<box-ip>
opkg update
opkg install neutrino-mediathek
```
Files land under `/usr/share/tuxbox/neutrino/plugins` and `/var/tuxbox/plugins`.

### Manual Copy / SFTP
```bash
git clone https://github.com/tuxbox-neutrino/neutrino-mediathek.git
scp -r neutrino-mediathek/plugins/neutrino-mediathek \
    root@<box-ip>:/usr/var/tuxbox/plugins
# or use FileZilla/WinSCP in SFTP mode
ssh root@<box-ip> "chmod 755 /usr/var/tuxbox/plugins/neutrino-mediathek/neutrino-mediathek.lua"
```
- Alternatively grab the latest tarball from the [Releases page](https://github.com/tuxbox-neutrino/neutrino-mediathek/releases).
- Restart Neutrino once copied.

### Configure the API URL
Default is `https://mt.api.tuxbox-neutrino.org/mt-api`. Change it only if you run your own backend.

- UI path: `Menu → Network Settings → API base URL`
- Stored as `apiBaseUrl=...` in `/var/tuxbox/config/neutrino-mediathek.conf`.

Manual edit (optional):
```bash
nano /var/tuxbox/config/neutrino-mediathek.conf
apiBaseUrl=https://your.host/mt-api
```
Restart Neutrino after editing.

## Tips for Smooth Playback
- Prefer images with LuaJIT: list rendering and filters stay snappy. Classic Lua 5.1 works but is slower on large lists.
- For local recordings, install GNU `findutils`; the BusyBox fallback works but scans can take longer.
- Local recordings: set the recording directory and optional directory blacklist in Settings (`Menu → Settings → Local recordings`). The blacklist (comma/semicolon separated) skips folders like `archive`, `.git`, `tmp` during scans.
- Make sure your box has a stable network connection to the configured API endpoint.

## Developer Corner

### Requirements
- Neutrino built from the DX repo (`make neutrino`, `make runtime-sync`).
- This repository checked out (e.g. `sources/neutrino-mediathek`) or pointed to via `NEUTRINO_MEDIATHEK_SRC`.
- Optional icon paths: defaults are `/usr/share/tuxbox/neutrino/icons/` and `/var/tuxbox/icons/`. Override when packaging with `ICONSDIR=/path ICONSDIR_VAR=/path make install`.
- A reachable Mediathek API (public or self-hosted).
- Handy tools: `curl`, `jq`, and `NEUTRINO_MEDIATHEK_API` for quick overrides.

### Local Build & Update
1. Clone if needed:
   ```bash
   git clone git@github.com:tuxbox-neutrino/neutrino-mediathek.git sources/neutrino-mediathek
   ```
2. Install into the sysroot: `make plugins`
3. Sync runtime payload: `make runtime-sync`
4. Start Neutrino (`ALLOW_NON_ROOT=1 make run-now` or `make run-direct`) and launch *Neutrino Mediathek*.

### Local Backend Workflow
```bash
# Update local importer + API
make -C services/mediathek-backend smoke

# Run Neutrino against the local backend
NEUTRINO_MEDIATHEK_API=http://localhost:18080/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```
Look for `[neutrino-mediathek] ...` in the console; cached JSON lives in `/tmp/neutrino-mediathek/`.

### Environment Override
Temporary URL override without touching configs:
```bash
NEUTRINO_MEDIATHEK_API=https://mt.api.tuxbox-neutrino.org/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```

### Connectivity Checks (curl & Lua)
Verify the backend answers before launching:
```bash
curl -s https://mt.api.tuxbox-neutrino.org/api/info | jq
curl -s https://mt.api.tuxbox-neutrino.org/api/listChannels | jq '.entry[:5]'
curl -s 'https://mt.api.tuxbox-neutrino.org/mt-api?mode=api&sub=list&channel=ZDF&limit=3' | jq
```
If these succeed, the plugin will work with the same URL.

## Troubleshooting
- **`Error connecting to database server`** – Wrong or unreachable API URL. Check the setting and retry with `curl`.
- **`curl: download ... size: 0`** – Backend returned an empty body. Inspect backend logs (`services/mediathek-backend/logs/`) or call `/api/listChannels` manually.
- **No changes after `git pull`** – Run `make plugins && make runtime-sync` to refresh the staged files.

## Backend References
- `services/mediathek-backend/docker` – importer/API Dockerfiles and Quickstart for local stacks.
- Upstream: [`tuxbox-neutrino/db-import`](https://github.com/tuxbox-neutrino/db-import) and [`tuxbox-neutrino/mt-api-dev`](https://github.com/tuxbox-neutrino/mt-api-dev). GitHub Actions publish the Docker images consumed here.
