Was ist Logomask?
---------------------------
Diese Plugin dient dazu, senderspezifisch die Senderlogos oder auch Laufschrif-
ten (z.B bei n-tv)mit einer oder mehreren schwarzen Masken abzudecken, um das
Fernsehbild ruhiger zu gestalten. Position und Größe der Masken werden dabei für
jeden Sender separat gespeichert und können auch für jeden einzelnen Videomodus
des Senders (4:3, 16:9 usw.) getrennt konfiguriert werden. Zur schnellen Anpassung
der Masken über die Fernbedienung enthält das Archiv auch das Konfigurationstool
"logoset".

Installation
------------
Die Speicherorte der Dateien ergeben sich aus der Archivstruktur. Das eigent-
liche Plugin "logomask" kommt mit den Rechten 755 nach /var/plugins/. Seine
Konfigurationsdatei "logomask.conf" legt das Plugin in /var/tuxbox/config ab.
Im Archiv ist die Konfigurationsdatei nur als Beispiel enthalten, da sie für
jede Box spezifisch angelegt werden muß. Das Plugin kann entweder direkt durch
den Eintrag "/var/plugins/logomask &" in einer der Neutrino-Startdateien gestar-
tet werden (das "&" im Eintrag ist wichtig), über den ebenfalls im Archiv be-
findlichen Shellstarter (logomask.cfg und logomask.so kommen nach /var/tuxbox/plugins/,
logomask.so mit den Rechten 755, logomask.sh kommt mit den Rechten 755 nach /var/plugins/),
oder, wenn des FlexMenü im Image vorhanden ist, durch Einfügen der ebenfalls im Archiv
enthaltenen Einträge in die shellexec.conf. Während im Flexmenü die jeweils sinn-
vollen Einträge (Starten oder Beenden) automatisch angeboten werden, kann man
beim Start über die blaue Taste das Plugin mit einem Aufruf starten und mit einem
erneuten Aufruf beenden.
Das Konfigurationsplugin "logoset" kommt mit den Rechten 755 nach /var/plugins/ und kann
ebenfalls über Shellstarter (logoset.cfg und logoset.so nach /var/tuxbox/plugins/,
logoset.so mit Rechten 755) oder über das FlexMenü gestartet werden.

Bedienung
---------
Bevor das Plugin genutzt werden kann, muß es mit dem Konfigurations-Plugin auf die
Senderlogos der gewünschten Sender eingestellt werden. Wurde ein Sender nicht kon-
figuriert, wird auch keine Maske dargestellt. Nach dem Umschalten auf einen anderen
Sender wartet das Plugin mit dem Löschen der alten und dem Anzeigen der neuen Masken
so lange, bis die InfoBar im unteren Bildbereich ausgeblendet wurde, damit diese
Information nicht gelöscht oder überschrieben wird.

Will man auf einem Sender die Masken aktivieren, stellt man diesen Sender ein und
startet das Konfigurations-Plugin. In der Mitte des Bildes wird nun ein blauer
Rahmen angezeigt. Diesen kann man mit den Richtungstasten der Fernbedienung nun so
auf dem Logo platzieren, daß der Rahmen mit seiner linken oberen Ecke schon auf der
richtigen Position steht. Nun kann mit der gelben Taste auf Größenveränderung umge-
schaltet werden (die Rahmenfarbe wechselt zu gelb). Mit den Rechts-/Links-Tasten
kann die Maskengröße jetzt horizontal vergrößert/verkleinert und mit den Runter-/Hoch-
tasten vertikal vergrößert/verkleinert werden. Will man die Position zwischendurch
noch einmal ändern, kann mit der blauen Taste auch wieder in den Positionierungsmo-
dus geschaltet werden (Rahmenfarbe wechselt wieder zu blau).
Die Schrittweite der Verschiebung erhöht sich bei länger gedrückter Taste, um eine
schnelle Positionierung zu ermöglichen. Wird länger als zwei Sekunden keine oder eine
andere als die bisherige Taste gedrückt, wird die Schrittweite wieder auf den Start-
wert gesetzt, damit eine Feinpositionierung durchgeführt werden kann. Bei längerem
Tastendruck wird die Schrittweite jedoch wieder erhöht.

Da Plasmafernseher auf die standardmäßig schwarzen Masken bei sehr langer Anzeige mit
Einbrenneffekten reagieren, kann die Farbe jeder einzelnen Maske mit der Mute-Taste
aus 15 Farben(Dbox) ausgewählt werden. Jeder Tastendruck schaltet zur nächsten Farbe. Em-
pfehlenswert für Plasmas ist Grau. Die gewählte Farbe wird so lange angezeigt, bis
wieder begonnen wird, die Maske zu bewegen.
Aufgrund des höheren Farbraums bei neueren Boxen ist hier sogar eine Farbgestaltung
der Masken möglich, welche keine Wünsche mehr offenlassen dürfte.

Für das Hinzufügen zusätzlicher Masken wird die grüne Taste betätigt. Die neue Maske
erscheint wieder in der Bildschirmmitte und kann, wie die vorhergende Maske konfigu-
riert werden. Für jeden Sender können maximal 16 Masken angelegt werden. Dabei wird
beim Konfigurieren immer die aktuelle Maske mit dem farbigen Rahmen angezeigt. Alle
anderen Masken werden normal schwarz dargestellt. Zwischen den einzelnen Masken kann
mittels der Lautstärke + und - Tasten weitergeschaltet werden.
Soll eine Maske nicht mehr dargestellt werden, so ist diese Maske mit den Volume-Tas-
ten auszuwählen und die rote Taste zu betätigen. Die selektierte Maske wird nun gelöscht
und die erste Maske in der Reihe (wenn vorhanden) wieder aktiv geschaltet.
Sitzen alle Masken richtig, kann die Einstellung mit der OK-Taste in die Konfigurations-
datei übernommen werden. Das Plugin "logomask", welches währen der Einstellung ge-
stoppt wurde, wird nun automatisch neu gestartet.
Der Hilfetext kann mit der "?"-Taste ein- und ausgeblendet werden.
Diese Einstellungen sind für die verschiedenen Videomodi der Box getrennt vorzunehmen.
Schaltet die Box auf einen Videomodus, welcher noch nicht konfiguriert wurde, wird die
Maske in der Bildmitte dargestellt und muß mit dem Konfigrations-Plugin einmalig ange-
passt werden.
Sollte ein Sender allerdings einen 16:9-Film im 4:3-Format senden und dabei sein Logo
weiter nach unten schieben, kann das die Box nicht erkennen. In diesem Fall kann man
die Maske aber auch schnell über die Fernbedienung neu positionieren.
Die Einstellungen werden generell nur mit der "OK"-Taste übernommen. Drückt man die
"Home"-Taste, wird die Konfiguration ohne Änderungen der Konfigurationsdatei abgebro-
chen.
