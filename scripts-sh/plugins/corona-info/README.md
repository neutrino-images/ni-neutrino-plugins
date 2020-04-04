## Corona-Info

<p>
  <img src="https://www.neutrino-images.de/channellogos/corona/corona.png" width="200" title="hover text">
</p>

von fred_feuerstein (NI-Team)

Ab 05.04.2020 ist das Plugin in den NI-Nightly Images enthalten.


In der aktuellen Situation mit Corona interessieren evt. einige von euch die aktuellen Fallzahlen von ausgewählten Ländern.

Ich habe ein kleines Plugin gebaut, das aus der Quelle: https://corona.lmao.ninja/countries für ausgewählte Länder die Fallzahlen holt.

Aktuelle Länder in der Übersicht: Deutschland, Italien, Spanien, USA, Oesterreich, Frankreich, Schweiz, Niederlande, China, UK, ...

Die Länder können in der Datei: corona.land im config-Verzeichnis der Box (var/tuxbox/config) geändert (hinzugefügt und gelöscht) und anders sortiert werden! Bitte die Struktur der Datei so belassen.

Zur Ausführung wird msgbox ab 2.14 und tuxwetter (für die Chart-Anzeige) auf der Box benötigt!

Installation:

- Zip Datei entpacken und die 4 Dateien in die Verzeichnis-Struktur aus dem Archiv auf die Box kopieren
     (corona.cfg, corona.so, corona_hint.png kommen ins Pluginverzeichnis und die corona.land in das config-Verzeichnis)
- Rechte der corona.so Datei auf 755 ändern.
- wer ggfs. andere Verzeichnisse für config und plugin nutzt, kann das ggfs. am Anfang des Scripts in den Variablen anpassen.
- wer Probleme mit dem WGET Abfruf hat kann am Anfang des Scripts die Variable von WGET auf CURL ändern, dann wird statt WGET eben CURL im Script genutzt
- Länder für die Übersicht können in der Datei corona.land editiert werden.

Das Plugin ist nun unter "Werkzeuge" auf der blauen Taste zu finden. Über die Menü-Einstellungen kann man es auch an andere Stellen setzen, wie bei anderen Plugins auch.

So sieht es aus:

<p>

  <img src="https://www.neutrino-images.de/channellogos/corona/screenshot3.png" width="500" title="hover text">
</p>
<p>

  <img src="https://www.neutrino-images.de/channellogos/corona/screenshot4.png" width="500" title="hover text">
</p>
<p>

  <img src="https://www.neutrino-images.de/channellogos/corona/screenshot5.png" width="500" title="hover text">
</p>

