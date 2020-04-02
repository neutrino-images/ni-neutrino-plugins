## Corona-Info

<p>
  <img src="https://www.neutrino-images.de/channellogos/corona/corona.png" width="200" title="hover text">
</p>

von fred_feuerstein (NI-Team)


In der aktuellen Situation mit Corona interessieren evt. einige von euch die aktuellen Fallzahlen von ausgewählten Ländern.

Ich habe ein kleines Plugin gebaut, das aus der Quelle: https://corona.lmao.ninja/countries für ausgewählte Länder die Fallzahlen holt.
Wenn euch noch weitere Länder interessieren, gebt hier im Thread Bescheid.

Aktuelle Länder in der Übersicht: Deutschland, Italien, Spanien, USA, Oesterreich, Frankreich, Schweiz, Niederlande, China, UK, ...

Die Länder können in der Datei: corona.land im Plugin-Verzeichnis geändert (hinzugefügt und gelöscht) und anders sortiert werden! Bitte die Struktur der Datei so belassen.

Installation:

- Zip Datei entpacken und die 4 Dateien nach /var/tuxbox/plugins (oder euer entsprechendes anderes Plugin-Verzeichnis) kopieren
- Rechte der corona.so Datei auf 755 ändern.
- Plugins neu laden im Menü, oder Box neu starten.
- wer Probleme mit dem WGET Abfruf hat kann am Anfang des Scripts die Variable von WGET auf CURL ändern, dann wird statt WGET eben CURL im Script genutzt
- Länder für die Übersicht können in der Datei corona.land editiert werden.

Das Plugin ist nun unter "Werkzeuge" auf der blauen Taste zu finden. Über die Menü-Einstellungen kann man es auch an andere Stellen setzen, wie bei anderen Plugins auch.


