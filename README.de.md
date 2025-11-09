# Neutrino Mediathek Plugin

## Überblick
Das Neutrino-Mediathek-Plugin ist ein Lua-Client, der auf die von der Community gepflegte Mediathek-API zugreift. Es kommuniziert mit einem REST-Backend (`mt-api`), das seine Daten über die `db-import`-Werkzeuge sammelt. Das Plugin lässt sich komplett lokal betreiben (alle Dienste in diesem Repository) oder nutzt wahlweise einen externen API-Endpunkt mit kompatibler Schnittstelle.

## Voraussetzungen
- Ein Neutrino-Build aus dem DX-Projekt (`make neutrino`, `make runtime-sync`).
- Dieses Repository als Checkout (z. B. unter `sources/neutrino-mediathek`) oder ein beliebiger Pfad, der per `NEUTRINO_MEDIATHEK_SRC` hinterlegt ist.
- Ein erreichbarer API-Endpunkt (lokal via `make -C services/mediathek-backend smoke` oder z. B. `https://test.novatux.de/mt-api`).
- Optional: die Umgebungsvariable `NEUTRINO_MEDIATHEK_API`, um den Endpunkt beim Start automatisch zu setzen.

## Installation & Aktualisierung (Generic-PC-Setup)
1. Repo klonen (falls noch nicht vorhanden):
   ```bash
   git clone git@github.com:tuxbox-neutrino/neutrino-mediathek.git sources/neutrino-mediathek
   ```
2. Plugin bauen/installieren: `make plugins`.
3. Runtime synchronisieren: `make runtime-sync`, damit die Dateien in `root/usr/share/tuxbox/neutrino/plugins` aktualisiert werden.
4. Neutrino starten (`ALLOW_NON_ROOT=1 make run-now` oder `make run-direct`) und das Plugin über das Hauptmenü öffnen.

## Deployment auf echten Boxen
Das Mini-Buildsystem hier dient nur für lokale PC-Tests. Auf Produktivboxen gehst du üblicherweise so vor:

1. **Paketverwaltung nutzen.** Das Image liefert ein `neutrino-mediathek`-Paket (ipk/opk). Über die GUI oder die Shell (`opkg install neutrino-mediathek.ipk`) installieren. Die Dateien landen automatisch unter `/usr/share/tuxbox/neutrino/plugins` bzw. `/var/tuxbox/plugins`.
2. **Manueller Kopierweg.** Neutrino stoppen, den Ordner `plugins/neutrino-mediathek` vom Repo nach `/usr/var/tuxbox/plugins` (oder `/usr/var/tuxbox/luaplugins`) kopieren/scp'en und auf korrekte Rechte achten (`chmod 755 neutrino-mediathek.lua`). Anschließend Neutrino neu starten.

Die Backend-/API-Konfiguration bleibt identisch zu den unten beschriebenen Schritten.

## API-Basis konfigurieren
- **Per Umgebungsvariable:** Vor dem Start `NEUTRINO_MEDIATHEK_API=<Schema>://<Host>/mt-api` exportieren. Die Docker-Laufzeit sowie der Neutrino-Wrapper reichen diese Variable jetzt vollständig durch, sodass das Plugin im Log u. a. `[neutrino-mediathek] NEUTRINO_MEDIATHEK_API=https://…` meldet.
- **Im Plugin-Menü:** `Menü → Netzwerkeinstellungen → API-Basis-URL` aufrufen und den gewünschten Endpunkt eintragen. Die Einstellung wird in `/var/tuxbox/config/neutrino-mediathek.conf` gespeichert; eine gesetzte Umgebungsvariable überschreibt sie nur während der aktuellen Session.

## Testablauf
```bash
make -C services/mediathek-backend smoke   # Backend aufsetzen
NEUTRINO_MEDIATHEK_API=http://localhost:18080/mt-api \
  ALLOW_NON_ROOT=1 make run-direct         # Neutrino inkl. Plugin starten
```
Danach im Hauptmenü *Neutrino Mediathek* wählen. Temporäre JSON-Dateien landen in `/tmp/neutrino-mediathek/`, und alle Debug-Ausgaben beginnen mit `[neutrino-mediathek]`.

## Fehlerhilfe
- `Error connecting to database server`: Der konfigurierte Endpunkt ist nicht erreichbar. URL im Log prüfen und Backend starten bzw. Netzwerkzugriff erlauben.
- Keine Sender/Livestreams sichtbar: Prüfen, ob der Importer gelaufen ist (`make -C services/mediathek-backend smoke`) bzw. ob der externe Endpunkt Daten liefert (`curl <Basis>/api/listChannels`).
- Änderungen erscheinen nicht: `make plugins` und anschließend `make runtime-sync` erneut ausführen.

## Backend-Hinweise
- Das lokale Backend befindet sich unter `services/mediathek-backend` (Docker-Compose mit MariaDB, Importer und API).
- Die Daten-Pipeline stammt aus `tuxbox-neutrino/db-import`, die API aus `tuxbox-neutrino/mt-api-dev`. Beide Repositories können über CI-Workflows automatisiert Daten aufbereiten, damit das Plugin stets aktuelle Inhalte erhält.
