# Neutrino Mediathek Plugin

Schneller Zugang zur Community-Mediathek direkt in Neutrino. Läuft mit dem öffentlichen API oder deinem eigenen Backend, solange es den gleichen Endpunkt spricht.

## Inhaltsverzeichnis
- [Was das Plugin macht](#was-das-plugin-macht)
- [Schnellstart für Anwender](#schnellstart-für-anwender)
  - [Installation über die UI-Paketverwaltung](#installation-über-die-ui-paketverwaltung)
  - [Installation via SSH-Paketmanager](#installation-via-ssh-paketmanager)
  - [Manuelles Kopieren / SFTP](#manuelles-kopieren--sftp)
  - [API-Basis konfigurieren](#api-basis-konfigurieren)
- [Tipps für flüssige Wiedergabe](#tipps-für-flüssige-wiedergabe)
- [Für Entwickler](#für-entwickler)
  - [Voraussetzungen](#voraussetzungen)
  - [Installation & Update (PC-Umgebung)](#installation--update-pc-umgebung)
  - [Lokaler Backend-Workflow](#lokaler-backend-workflow)
  - [Umgebungsvariable (Tests)](#umgebungsvariable-tests)
  - [Konnektivität testen (curl & Lua)](#konnektivität-testen-curl--lua)
- [Fehlersuche](#fehlersuche)
- [Backend-Referenzen](#backend-referenzen)

## Was das Plugin macht
- Durchstöbert und spielt Mediathek-Inhalte über das `mt-api`-Backend (Standard: `https://mt.api.tuxbox-neutrino.org/mt-api`).
- Reines Lua, keine Kompilierung auf der Box nötig.
- Funktioniert mit lokalen oder entfernten Backends, solange sie die gleiche REST-Schnittstelle anbieten.

## Schnellstart für Anwender

### Installation über die UI-Paketverwaltung
Falls ein Paketmanager vorhanden ist:
- *Service → Software-Aktualisierung → Paketverwaltung* öffnen.
- `neutrino-mediathek` auswählen, installieren, GUI neu starten.

### Installation via SSH-Paketmanager
```bash
ssh root@<box-ip>
opkg update
opkg install neutrino-mediathek
```
Dateien landen unter `/usr/share/tuxbox/neutrino/plugins` und `/var/tuxbox/plugins`.

### Manuelles Kopieren / SFTP
```bash
git clone https://github.com/tuxbox-neutrino/neutrino-mediathek.git
scp -r neutrino-mediathek/plugins/neutrino-mediathek \
    root@<box-ip>:/usr/var/tuxbox/plugins
# oder FileZilla/WinSCP im SFTP-Modus
ssh root@<box-ip> "chmod 755 /usr/var/tuxbox/plugins/neutrino-mediathek/neutrino-mediathek.lua"
```
- Alternativ: Tarball von der [Releases-Seite](https://github.com/tuxbox-neutrino/neutrino-mediathek/releases) herunterladen.
- Danach Neutrino neu starten.

### API-Basis konfigurieren
Standard ist `https://mt.api.tuxbox-neutrino.org/mt-api`. Nur ändern, wenn du einen eigenen Endpunkt nutzt.

- Menüpfad: `Menü → Netzwerk-Einstellungen → API-Basis-URL`
- Gespeichert als `apiBaseUrl=...` in `/var/tuxbox/config/neutrino-mediathek.conf`.

Manuell editieren (optional):
```bash
nano /var/tuxbox/config/neutrino-mediathek.conf
apiBaseUrl=https://dein.host/mt-api
```
Nach Änderungen Neutrino neu starten.

## Tipps für flüssige Wiedergabe
- Bevorzuge Images mit LuaJIT: Listen und Filter reagieren deutlich schneller. Lua 5.1 funktioniert, ist aber bei großen Listen träger.
- Für lokale Aufnahmen GNU `findutils` installieren; der BusyBox-Fallback funktioniert, kann aber länger brauchen.
- Netzwerk zur gewählten API stabil halten.

## Für Entwickler

### Voraussetzungen
- Neutrino aus dem DX-Repo gebaut (`make neutrino`, `make runtime-sync`).
- Dieses Repository ausgecheckt (z. B. `sources/neutrino-mediathek`) oder via `NEUTRINO_MEDIATHEK_SRC` gesetzt.
- Optionale Icon-Pfade: Standard `/usr/share/tuxbox/neutrino/icons/` und `/var/tuxbox/icons/`; beim Packen per `ICONSDIR=/pfad ICONSDIR_VAR=/pfad make install` überschreibbar.
- Erreichbares Mediathek-API (öffentlich oder selbst gehostet).
- Praktische Helfer: `curl`, `jq` und `NEUTRINO_MEDIATHEK_API` für schnelle URL-Overrides.

### Installation & Update (PC-Umgebung)
1. Repo klonen (falls noch nicht vorhanden):
   ```bash
   git clone git@github.com:tuxbox-neutrino/neutrino-mediathek.git sources/neutrino-mediathek
   ```
2. Plugin ins Sysroot installieren: `make plugins`
3. Runtime synchronisieren: `make runtime-sync`
4. Neutrino starten (`ALLOW_NON_ROOT=1 make run-now` oder `make run-direct`) und *Neutrino Mediathek* öffnen.

### Lokaler Backend-Workflow
```bash
# Importer + API lokal aktualisieren
make -C services/mediathek-backend smoke

# Neutrino gegen das lokale Backend starten
NEUTRINO_MEDIATHEK_API=http://localhost:18080/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```
Konsole auf `[neutrino-mediathek] ...` achten; Cache liegt in `/tmp/neutrino-mediathek/`.

### Umgebungsvariable (Tests)
Temporärer URL-Override ohne Config-Änderung:
```bash
NEUTRINO_MEDIATHEK_API=https://mt.api.tuxbox-neutrino.org/mt-api \
  ALLOW_NON_ROOT=1 make run-direct
```

### Konnektivität testen (curl & Lua)
Vor dem Start prüfen, ob das Backend antwortet:
```bash
curl -s https://mt.api.tuxbox-neutrino.org/api/info | jq
curl -s https://mt.api.tuxbox-neutrino.org/api/listChannels | jq '.entry[:5]'
curl -s 'https://mt.api.tuxbox-neutrino.org/mt-api?mode=api&sub=list&channel=ZDF&limit=3' | jq
```
Wenn das klappt, läuft das Plugin mit derselben URL.

## Fehlersuche
- **`Error connecting to database server`** – URL falsch oder Backend nicht erreichbar. Einstellung prüfen, per `curl` testen.
- **`curl: download ... size: 0`** – Backend liefert nichts. Logs unter `services/mediathek-backend/logs/` prüfen oder `/api/listChannels` manuell aufrufen.
- **Keine Änderung nach `git pull`** – `make plugins && make runtime-sync` ausführen, damit die gestagten Dateien aktualisiert werden.

## Backend-Referenzen
- `services/mediathek-backend/docker`: Dockerfiles + Quickstart für Importer/API.
- Upstream: [`tuxbox-neutrino/db-import`](https://github.com/tuxbox-neutrino/db-import) und [`tuxbox-neutrino/mt-api-dev`](https://github.com/tuxbox-neutrino/mt-api-dev). Deren Actions veröffentlichen die genutzten Docker-Images.
