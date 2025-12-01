# Neutrino Mediathek Plugin

## Table of Contents
- [Overview](#overview)
- [For Users](#for-users)
  - [Install via UI Package Manager](#install-via-ui-package-manager)
  - [Install via SSH Package Manager](#install-via-ssh-package-manager)
  - [Manual Copy / SFTP](#manual-copy--sftp)
  - [Configure the API URL](#configure-the-api-url)
    - [UI Setting](#ui-setting)
    - [Manual Config Edit](#manual-config-edit)
- [For Developers](#for-developers)
  - [Requirements](#requirements)
  - [Local Build & Update](#local-build--update)
  - [Local Backend Workflow](#local-backend-workflow)
  - [Environment Override](#environment-override)
  - [Connectivity Checks (curl & Lua)](#connectivity-checks-curl--lua)
  - [Lua Connectivity Harness](#lua-connectivity-harness)
- [Troubleshooting](#troubleshooting)
- [Backend References](#backend-references)

## Overview
The Neutrino Mediathek plugin is a Lua-based client for the community-driven Mediathek API. It talks to the `mt-api` backend (which in turn is supplied by the `db-import` toolchain) and works either against a locally hosted stack from this repository or any remote endpoint that implements the same REST contract (e.g. `https://mt.api.tuxbox-neutrino.org/mt-api`).

## For Users


### Install via UI Package Manager
On images where the package manager was enabled during the Neutrino build and packages are provided:

- Navigate to *Service → Software Update → Package Manager*.
- Select `neutrino-mediathek`, install it, and restart the GUI.

### Install via SSH Package Manager
```bash
ssh root@<box-ip>
opkg update
opkg install neutrino-mediathek
```
Files are placed under `/usr/share/tuxbox/neutrino/plugins` and `/var/tuxbox/plugins`.

### Manual Copy / SFTP
```bash
git clone https://github.com/tuxbox-neutrino/neutrino-mediathek.git
scp -r neutrino-mediathek/plugins/neutrino-mediathek \
    root@<box-ip>:/usr/var/tuxbox/plugins
# or use FileZilla/WinSCP in SFTP mode
ssh root@<box-ip> "chmod 755 /usr/var/tuxbox/plugins/neutrino-mediathek/neutrino-mediathek.lua"
```
- Alternatively download the latest tarball from the [Releases page](https://github.com/tuxbox-neutrino/neutrino-mediathek/releases) instead of cloning.
- Restart Neutrino once the files are in place.

### Configure the API URL
The plugin ships preconfigured for the public endpoint `https://mt.api.tuxbox-neutrino.org/mt-api`. You only need to adjust it if you want to use another API.

#### UI Setting
- Menu path: `Menu → Network Settings → API base URL`
- Enter the new endpoint and confirm. The value is stored in `/var/tuxbox/config/neutrino-mediathek.conf` (mirrored under `root/var/tuxbox/config/...` in the build tree) as `apiBaseUrl=...`.

#### Manual Config Edit
```bash
nano /var/tuxbox/config/neutrino-mediathek.conf
# or copy the file to your PC, edit it, and copy it back
apiBaseUrl=https://your.host/mt-api
```
Restart Neutrino after editing.

## For Developers

### Requirements
- A Neutrino build created from the DX repo (`make neutrino`, `make runtime-sync`).
- A Neutrino image that ships LuaJIT (recommended). The plugin also runs with the classic Lua 5.1 interpreter, but rendering/filtering large result lists is noticeably slower there.
- This repository checked out next to the build tree (e.g. `sources/neutrino-mediathek`) or pointed to via `NEUTRINO_MEDIATHEK_SRC`.
- Optional icon directories: by default the plugin uses `/usr/share/tuxbox/neutrino/icons/` (system) and `/var/tuxbox/icons/` (user). When packaging you can override them via `ICONSDIR=/path/... ICONSDIR_VAR=/path/... make install` (matching Neutrino's configure variables).
- A reachable API endpoint speaking the Mediathek contract (self-hosted or public).
- Optional but handy: `curl` and `jq` for API smoke tests, and the `NEUTRINO_MEDIATHEK_API` environment variable for quick overrides.
- For local recordings: a `find` that supports `-printf` (GNU findutils). BusyBox `find` often lacks this flag; install `findutils` or ensure a compatible `find` is in `PATH`.

### Local Build & Update
1. Clone this repo next to your DX sources (if not already present):
   ```bash
   git clone git@github.com:tuxbox-neutrino/neutrino-mediathek.git sources/neutrino-mediathek
   ```
2. Build/install the plugin into the sysroot: `make plugins`.
3. Synchronise the staged runtime payload: `make runtime-sync`.
4. Launch Neutrino (`ALLOW_NON_ROOT=1 make run-now` or `make run-direct`) and open *Neutrino Mediathek* from the menu.

### Local Backend Workflow
```bash
# Refresh local backend data / containers (if you run them yourself)
make -C services/mediathek-backend smoke

# Start Neutrino and point the plugin to that backend
NEUTRINO_MEDIATHEK_API=http://localhost:18080/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```

Watch the console for `[neutrino-mediathek] …` log lines; cached JSON lives in `/tmp/neutrino-mediathek/`.

### Environment Override
Handy for automated tests or quick checks without touching configs:

```bash
NEUTRINO_MEDIATHEK_API=https://mt.api.tuxbox-neutrino.org/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```

The override only affects the current session; the config file remains unchanged.

### Connectivity Checks (curl & Lua)
Before launching Neutrino, verify the endpoint responds:

```bash
curl -s https://mt.api.tuxbox-neutrino.org/api/info | jq
curl -s https://mt.api.tuxbox-neutrino.org/api/listChannels | jq '.entry[:5]'
curl -s 'https://mt.api.tuxbox-neutrino.org/mt-api?mode=api&sub=list&channel=ZDF&limit=3' | jq
```

If these succeed, the plugin will work with the same URL.

### Lua Connectivity Harness
Need an automated check that uses the plugin’s Lua helpers?

```bash
cat >/tmp/test_api.lua <<'EOF'
package.path = '/path/to/neutrino-make/plugins/vendor/share/lua/5.2/?.lua;'..package.path
local JSON = require('json')
pluginTmpPath = '/tmp/neutrino-mediathek-plugin-test'
os.execute('mkdir -p '..pluginTmpPath)
jsonData = pluginTmpPath..'/mediathek_data.txt'
noCacheFiles = true
queryMode_None, queryMode_Info, queryMode_listChannels = 0, 1, 2
H = { printf=function(...) io.stdout:write(string.format(... )..'\n') end,
      fileExist=function(f) local h=io.open(f,'r'); if h then h:close(); return true end end,
      trim=function(s) return (s:gsub('^%s+',''):gsub('%s+$','')) end,
      base64Dec=function(s) return s end }
G = { hideInfoBox=function() end, paintInfoBox=function() end }
CURL={OK=0}
function curlDownload(url,file,post) return nil, os.execute(string.format("curl -fsSL %q -o %q",url,file))==0 and CURL.OK or 1 end
J=JSON
dofile('/path/to/neutrino-mediathek/neutrino-mediathek/json_decode.lua')
local function query(endpoint, mode)
  local file = pluginTmpPath..'/'..mode..'.json'
  local body = getJsonData2(endpoint, file, nil, mode)
  local parsed = decodeJson(body); assert(checkJsonError(parsed))
  return parsed
end
local base='https://mt.api.tuxbox-neutrino.org/mt-api'
print('info entries', #query(base..'/api/info', queryMode_Info).entry)
print('channels entries', #query(base..'/api/listChannels', queryMode_listChannels).entry)
EOF
root/usr/bin/luajit /tmp/test_api.lua
```

If both curl and the Lua harness succeed, the plugin will also be able to talk to the API.

## Troubleshooting
- **`Error connecting to database server`** – The API endpoint was unreachable. Check the configured base URL (log + config file) and confirm the backend answers via `curl`.
- **`curl: download ... size: 0`** – Backend responded with an empty body. Inspect the backend logs (`services/mediathek-backend/logs/`) or call `/api/listChannels` manually to uncover HTTP errors.
- **No plugin updates after git pull** – Re-run `make plugins && make runtime-sync` to refresh the staged files before launching Neutrino.

## Backend References
- `services/mediathek-backend/docker` – importer/API Dockerfiles and Quickstart script for local stacks.
- Upstream components: [`tuxbox-neutrino/db-import`](https://github.com/tuxbox-neutrino/db-import) and [`tuxbox-neutrino/mt-api-dev`](https://github.com/tuxbox-neutrino/mt-api-dev). Their GitHub Actions workflows publish the Docker images consumed here.
