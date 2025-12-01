# Neutrino Mediathek Plugin

## Inhaltsverzeichnis
- [Überblick](#überblick)
- [Für Anwender](#für-anwender)
  - [Installation über die UI-Paketverwaltung](#installation-über-die-ui-paketverwaltung)
  - [Installation via SSH-Paketmanager](#installation-via-ssh-paketmanager)
  - [Manuelles Kopieren / SFTP](#manuelles-kopieren--sftp)
  - [API-Basis konfigurieren](#api-basis-konfigurieren)
- [Für Entwickler](#für-entwickler)
  - [Voraussetzungen](#voraussetzungen)
  - [Installation & Update (PC-Umgebung)](#installation--update-pc-umgebung)
  - [Lokaler Workflow](#lokaler-workflow)
  - [Umgebungsvariable (Tests)](#umgebungsvariable-tests)
  - [Konnektivität testen (curl & Lua)](#konnektivität-testen-curl--lua)
  - [Lua-Testskript](#lua-testskript)
- [Fehlersuche](#fehlersuche)
- [Backend-Referenzen](#backend-referenzen)

## Überblick
Das Plugin ist ein Lua-Client für die Community-Mediathek-API. Es spricht das REST-Backend `mt-api`, dessen Daten durch das `db-import`-Toolchain aggregiert werden. Der Zugriff funktioniert sowohl gegen lokal betriebene Dienste (aus diesem Repo) als auch gegen entfernte Endpunkte wie `https://mt.api.tuxbox-neutrino.org/mt-api`.

## Für Anwender

### Installation über die UI-Paketverwaltung
Wenn der Paketmanager beim Neutrino-Build aktiviert wurde und Pakete bereitstehen:

- *Service → Software-Aktualisierung → Paketverwaltung* öffnen.
- `neutrino-mediathek` auswählen, installieren und die GUI neu starten.

### Installation via SSH-Paketmanager
```bash
ssh root@<box-ip>
opkg update
opkg install neutrino-mediathek
```
Die Dateien landen unter `/usr/share/tuxbox/neutrino/plugins` und `/var/tuxbox/plugins`.

### Manuelles Kopieren / SFTP
```bash
git clone https://github.com/tuxbox-neutrino/neutrino-mediathek.git
scp -r neutrino-mediathek/plugins/neutrino-mediathek \
    root@<box-ip>:/usr/var/tuxbox/plugins
# oder FileZilla/WinSCP im SFTP-Modus verwenden
ssh root@<box-ip> "chmod 755 /usr/var/tuxbox/plugins/neutrino-mediathek/neutrino-mediathek.lua"
```
- Alternativ die auf der [Releases-Seite](https://github.com/tuxbox-neutrino/neutrino-mediathek/releases) automatisch erzeugten Tarballs herunterladen.
- Nach dem Kopieren Neutrino neu starten.

### API-Basis konfigurieren
Das Plugin nutzt standardmäßig `https://mt.api.tuxbox-neutrino.org/mt-api`. Nur wenn du einen anderen API-Endpunkt verwenden willst, musst du die Einstellung anpassen.

#### Einstellung im Plugin
- Menüpfad: `Menü → Netzwerk-Einstellungen → API-Basis-URL`
- Wert eintragen, bestätigen. Gespeichert als `apiBaseUrl` in `/var/tuxbox/config/neutrino-mediathek.conf` (im Build-Tree unter `root/var/tuxbox/config/...` sichtbar).

#### Manuelles Editieren
```bash
nano /var/tuxbox/config/neutrino-mediathek.conf
# oder die Datei auf den PC kopieren, bearbeiten und zurückkopieren
apiBaseUrl=https://dein.host/mt-api
```
Nach der Änderung Neutrino neu starten.

## Für Entwickler

### Voraussetzungen
- Mit dem DX-Repo gebautes Neutrino (`make neutrino`, `make runtime-sync`).
- Empfehlenswert ist ein Neutrino-Image mit LuaJIT. Das Plugin funktioniert zwar mit der klassischen Lua-5.1-Laufzeit, aber das Durchblättern großer Listen reagiert dort spürbar träger.
- Dieses Repository als Checkout (z. B. `sources/neutrino-mediathek`) oder über `NEUTRINO_MEDIATHEK_SRC`.
- Optionale Icon-Pfade: standardmäßig werden `/usr/share/tuxbox/neutrino/icons/` (System) und `/var/tuxbox/icons/` (Benutzer) verwendet. Beim Packen lassen sie sich via `ICONSDIR=/pfad/... ICONSDIR_VAR=/pfad/... make install` anpassen (dieselben Namen wie in Neutrinos `./configure`).
- Ein erreichbares API-Backend (lokal via `make -C services/mediathek-backend smoke` oder öffentlich).
- Optional: `curl`, `jq` sowie das Environment `NEUTRINO_MEDIATHEK_API`, um die URL bequem zu überschreiben.
- Für lokale Aufnahmen: das System muss ein `find` mit `-printf` unterstützen (GNU findutils). Auf manchen BusyBox-Images fehlt `-printf`; dann bitte `findutils` nachinstallieren oder sicherstellen, dass ein kompatibles `find` im PATH liegt.

### Installation & Update (PC-Umgebung)
1. Repository klonen:
   ```bash
   git clone git@github.com:tuxbox-neutrino/neutrino-mediathek.git sources/neutrino-mediathek
   ```
2. Plugin bauen/installieren: `make plugins`
3. Runtime synchronisieren: `make runtime-sync`
4. Neutrino starten (`ALLOW_NON_ROOT=1 make run-now` oder `make run-direct`) und *Neutrino Mediathek* im Menü auswählen.

### Lokaler Workflow
```bash
# Backend (Importer + API) lokal aktualisieren
make -C services/mediathek-backend smoke

# Neutrino starten und Plugin auf das Backend zeigen lassen
NEUTRINO_MEDIATHEK_API=http://localhost:18080/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```

Logs tragen das Präfix `[neutrino-mediathek]`, temporäre JSON-Dateien liegen in `/tmp/neutrino-mediathek/`.

### Umgebungsvariable (Tests)
Praktisch für automatische Tests oder kurzfristige Checks:

```bash
NEUTRINO_MEDIATHEK_API=https://mt.api.tuxbox-neutrino.org/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```

Wirkt nur für die aktuelle Sitzung; die Konfigurationsdatei bleibt unverändert.

### Konnektivität testen (curl & Lua)
Vor dem Pluginstart sollte das Backend erreichbar sein:

```bash
curl -s https://mt.api.tuxbox-neutrino.org/api/info | jq
curl -s https://mt.api.tuxbox-neutrino.org/api/listChannels | jq '.entry[:5]'
curl -s 'https://mt.api.tuxbox-neutrino.org/mt-api?mode=api&sub=list&channel=ZDF&limit=3' | jq
```

Wenn diese Aufrufe funktionieren, läuft das Plugin mit derselben URL.

### Lua-Testskript
Lua-basierter Check (nutzt dieselben Helper wie das Plugin):

```bash
cat >/tmp/test_api.lua <<'EOF'
package.path = '/pfad/zu/neutrino-make/plugins/vendor/share/lua/5.2/?.lua;'..package.path
local JSON = require('json')
pluginTmpPath = '/tmp/neutrino-mediathek-plugin-test'
os.execute('mkdir -p '..pluginTmpPath)
jsonData = pluginTmpPath..'/mediathek_data.txt'
noCacheFiles = true
queryMode_None, queryMode_Info, queryMode_listChannels = 0, 1, 2
H = { printf=function(...) io.stdout:write(string.format(... )..'\\n') end,
      fileExist=function(f) local h=io.open(f,'r'); if h then h:close(); return true end end,
      trim=function(s) return (s:gsub('^%s+',''):gsub('%s+$','')) end,
      base64Dec=function(s) return s end }
G = { hideInfoBox=function() end, paintInfoBox=function() end }
CURL={OK=0}
function curlDownload(url,file,post) return nil, os.execute(string.format("curl -fsSL %q -o %q",url,file))==0 and CURL.OK or 1 end
J=JSON
dofile('/pfad/zu/neutrino-mediathek/neutrino-mediathek/json_decode.lua')
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

## Fehlersuche
- **`Error connecting to database server`** – URL falsch oder Backend nicht erreichbar. Adresse prüfen, per `curl` testen.
- **`curl: download ... size: 0`** – Backend liefert keinen Inhalt. `services/mediathek-backend/logs/` prüfen oder `/api/listChannels` direkt aufrufen.
- **Keine Aktualisierung nach `git pull`** – `make plugins && make runtime-sync` erneut ausführen, damit die gestagten Dateien aktualisiert werden.

## Backend-Referenzen
- `services/mediathek-backend/docker`: Dockerfiles + Quickstart für Importer/API.
- Upstream-Projekte: [`tuxbox-neutrino/db-import`](https://github.com/tuxbox-neutrino/db-import) und [`tuxbox-neutrino/mt-api-dev`](https://github.com/tuxbox-neutrino/mt-api-dev). Deren Workflows veröffentlichen die Docker-Images, die das Plugin nutzt.
