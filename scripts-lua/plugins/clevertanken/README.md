# NI-CleverTanken 0.6.7

Lua-Plugin für NI-Neutrino zur Anzeige aktueller Kraftstoffpreise von Tankstellen in der Umgebung.

## Funktionen
- Diesel, Super E5 und Super E10; Sortierung nach Preis, bei Gleichstand nach Entfernung
- Standortsuche über deutsche Postleitzahl mit Ortsauswahl
- Plausibilitätsprüfung der Koordinaten; OpenStreetMap Nominatim als Fallback bei fehlerhaften Daten von Zippopotam.us
- **Bis zu fünf Standort-Favoriten** speichern, auswählen und löschen, ohne die PLZ erneut einzugeben
- Einstellbarer Suchradius (1–25 km), Tankstellendetails, Entfernung und Öffnungsstatus
- Preisentwicklung gegenüber dem Vortag (Messwert zur ähnlichen Uhrzeit, ±1 Stunde); `v` = gesunken, `^` = gestiegen, `=` = unverändert. Ohne Vergleichswert bleibt die Trendanzeige leer.
- 5-Minuten-Cache pro Suchkonfiguration und globaler Mindestabstand von 60 Sekunden zwischen API-Abfragen
- Filter für Tankstellennamen, die mit eigenständigem `TS` beginnen
- OSD für 720p und 1080p

## Voraussetzungen
NI-Neutrino mit Lua, `cjson`, `curl` und CA-Zertifikat unter `/etc/ssl/certs/ca-certificates.crt`.
Für echte Kraftstoffpreise wird ein **eigener Tankerkönig-API-Key** benötigt.

## Installation
1. `clevertanken.lua` und `clevertanken.cfg` nach `/usr/share/tuxbox/neutrino/plugins/` kopieren.
2. **Nur bei Neuinstallation:** `clevertanken.beispiel.conf` nach `/var/tuxbox/config/clevertanken.conf` kopieren und den Demo-Schlüssel durch den eigenen API-Key ersetzen.
3. **Bei Updates:** Die vorhandene `/var/tuxbox/config/clevertanken.conf` **nicht überschreiben**. Die Favoriten bleiben in ihrer separaten Datei erhalten.
4. Plugin starten; über BLAU → Einstellungen → OK den Standort per PLZ auswählen.

## Bedienung
**Hauptansicht:** ROT schließen, GRÜN aktualisieren, GELB Kraftstoff wechseln, BLAU Einstellungen; AUF/AB Tankstelle auswählen, OK Details, LINKS/RECHTS Seitenwechsel.

**Einstellungen:** OK PLZ-Suche, GRÜN/GELB Suchradius ändern, BLAU Favoriten öffnen, ROT zurück.

**Favoriten:** GRÜN aktuellen Standort speichern (maximal fünf; keine doppelten Standorte), AUF/AB auswählen, OK übernehmen, GELB zweimal löschen, ROT zurück. Der aktive Standort wird gekennzeichnet.

Die Favoriten werden in `/var/tuxbox/config/clevertanken_favorites.json` gespeichert; diese Datei enthält keinen API-Key und darf beim Update nicht überschrieben werden.

## Datenschutz und Repository
**Nie** persönliche Konfigurationen oder Laufzeitdateien committen: `clevertanken.conf`, `clevertanken_favorites.json`, `clevertanken_cache.json`, `clevertanken_history.tsv`.
Der Cache-Schlüssel enthält den API-Key. API-Anfragen enthalten den Key in der URL; daher Logs und Debug-Ausgaben vorsichtig behandeln.
Die mitgelieferte Beispielkonfiguration enthält ausschließlich einen öffentlichen Demo-Schlüssel, der keine echten Preise liefert.

## Datenquellen und Lizenzen
- Kraftstoffpreise: Tankerkönig – https://creativecommons.tankerkoenig.de/ (Datenlizenz **CC BY 4.0**). Die Quellenangabe wird im Plugin angezeigt.
- Postleitzahl-/Ortskoordinaten: Zippopotam.us – https://www.zippopotam.us/.
- Fallback für Standortkoordinaten: OpenStreetMap Nominatim – https://nominatim.org/; Daten © OpenStreetMap-Mitwirkende (**ODbL**). Nutzungsrichtlinie: https://operations.osmfoundation.org/policies/nominatim/. Keine automatisierten Massenabfragen; Nutzungsbedingungen und Attribution beachten.

**Softwarelizenz:** GNU General Public License Version 3 (**GPL-3.0-only**). Der vollständige Text steht in `LICENSE`. Die Softwarelizenz ersetzt nicht die separaten Lizenzen der verwendeten Daten und Dienste.

## Teststand und Hinweise
Die Hauptansicht, Einstellungen und Favoritenverwaltung wurden auf Neutrino Box 1 mit 720p und 1080p anhand von Screenshots geprüft. Speichern, Wechseln und Löschen von Favoriten einschließlich des aktiven Standorts wurden getestet. Tests auf weiteren Boxen und Rückmeldungen sind willkommen.

Bei zuvor gespeicherten fehlerhaften Standortkoordinaten den Standort unter Einstellungen über die PLZ-Suche erneut auswählen.

