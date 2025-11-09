# Neutrino Mediathek Plugin

## Overview
The Neutrino Mediathek plugin provides a Lua-based client for the community-driven Mediathek API. It talks to a REST-ish backend (`mt-api`) that aggregates public broadcaster content via the `db-import` toolchain. The plugin can run completely locally (all services inside this repository) or consume a remote API endpoint that exposes the same contract.

## Requirements
- A Neutrino build produced from the DX repo (`make neutrino`, `make runtime-sync`).
- This repository checked out next to the build tree (e.g. `sources/neutrino-mediathek` inside `neutrino-generic-build`) or anywhere else referenced via `NEUTRINO_MEDIATHEK_SRC`.
- A reachable API endpoint that implements the Mediathek contract (either run `make -C services/mediathek-backend smoke` locally or use a hosted URL such as `https://test.novatux.de/mt-api`).
- Optional: `NEUTRINO_MEDIATHEK_API` environment variable if you want to override the API base automatically during launch.

## Installation & Update (Generic PC dev setup)
1. Clone this repo next to the DX sources (if not already present):
   ```bash
   git clone git@github.com:tuxbox-neutrino/neutrino-mediathek.git sources/neutrino-mediathek
   ```
2. Build/install the plugin into the sysroot: `make plugins`.
3. Synchronise the runtime payload so the staged `/usr/share/tuxbox/neutrino/plugins` copy is up to date: `make runtime-sync`.
4. Start Neutrino (e.g. `ALLOW_NON_ROOT=1 make run-now`) or run the host wrapper via `make run-direct`.

## Deploying to actual Neutrino boxes
The demo build system is only meant for local development. To ship the plugin to a set-top box you typically use one of these paths:

1. **Package manager (`ipkg`/`opkg`).** Build or fetch the `neutrino-mediathek` package produced by your image and install it via GUI (Softwareverwaltung) or CLI (`opkg install neutrino-mediathek.ipk`). The package drops files under `/usr/share/tuxbox/neutrino/plugins` and `/var/tuxbox/plugins`.
2. **Manual copy.** Stop Neutrino, scp the directory `plugins/neutrino-mediathek` to the box, normally into `/usr/var/tuxbox/plugins` (or `/usr/var/tuxbox/luaplugins` on some images). Keep executable bits on `neutrino-mediathek.lua` (`chmod 755`) and ensure the locale/JSON helper files preserve their relative structure. Restart Neutrino afterwards.

The backend configuration steps below stay the same; only the transport to the device differs.

## Configure the API base
- **Environment variable:** Export `NEUTRINO_MEDIATHEK_API=<scheme>://<host>/mt-api` before invoking `make run-direct` / `make run`. The build wrapper now forwards this variable through Docker as well as the Neutrino runtime wrapper, so the plugin logs a line such as `[neutrino-mediathek] NEUTRINO_MEDIATHEK_API=https://test.novatux.de/mt-api`.
- **In-UI setting:** Open the plugin → `Menu` → `Network Settings` → `API base URL` and enter the endpoint. This writes `/var/tuxbox/config/neutrino-mediathek.conf`. Environment overrides take precedence during the current session but do not overwrite the stored value.

## Testing workflow
```bash
# Start / refresh backend data (local stack)
make -C services/mediathek-backend smoke

# Launch Neutrino and force the plugin to talk to that backend
NEUTRINO_MEDIATHEK_API=http://localhost:18080/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```
Open *Neutrino Mediathek* from the main menu. The plugin writes verbose traces prefixed with `[neutrino-mediathek]` to the console. Temporary JSON payloads live under `/tmp/neutrino-mediathek/`.

## Troubleshooting
- `Error connecting to database server`: The API endpoint was unreachable. Check the URL in the log output and ensure the backend is running (or reachable through your tunnel/proxy).
- `curl: download ... size: 0`: The API returned an empty body. Inspect the backend logs (`services/mediathek-backend/logs/`) or query the endpoint manually via `curl <base>/api/listChannels`.
- Missing plugin entries: rerun `make plugins` after pulling new sources, then `make runtime-sync`.

## Backend references
- `services/mediathek-backend/docker` provides importer/API containers for local development.
- Upstream toolchains live under `https://github.com/tuxbox-neutrino/db-import` and `https://github.com/tuxbox-neutrino/mt-api-dev`. Automating those repos (e.g. via GitHub Actions) keeps the public API feed fresh.
