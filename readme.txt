Was ist die Messagebox?
----------------------------------
Die MessageBox dient beim Ausführen von Scripten zur Anzeige von Informationen auf dem
Bildschirm und zur Abfrage von Entscheidungen des Nutzers über bis zu 24 frei beschrift-
bare Tasten. Die Nummer der gedrückten Taste (1..24) oder 0 bei Timeout ohne gedrückte
Taste wird als Returnwert zurückgegeben und kann vom Script über die Variable "$?" ausge-
wertet werden.


Installation
----------------------------------
Es wird nur die Datei "msgbox" benötigt. Abhängig vom Image-Typ ist diese entweder in
/bin/ (bei JFFS-Only) oder /var/bin/ (bei CRAMFS und SQUASHFS) zu kopieren und mit den
Rechten 755 zu versehen. Nun kann sie aus eigenen Scripten heraus verwendet werden. Eine
spezielle Busybox ist für die Verwendung von "msgbox" nicht erforderlich.


Anwendung
----------------------------------
Der Aufruf der MessageBox erfolgt über die Ausführung von "msgbox" mit entsprechenden Pa-
rametern. Im Folgenden werden nun die möglichen Parameter beschrieben.
Das wichtigste ist natürlich der anzuzeigende Text. Dieser kann entweder über die Kommando-
zeile oder aus einer Datei übergeben werden. Die Art der Textanzeige (Message oder Popup)
wird über die Schlüsselwörter "msg=" für Message und "popup=" für Popup festgelegt.
Um nun einen Text von der Kommandozeile als Popup anzuzeigen, erfolgt der Aufruf in dieser
Form:

msgbox popup="Auszugebender Text"

für eine Message entsprechend:

msgbox msg="Auszugebender Text"

Der Text muß dabei in Hochkommas stehen. Soll der anzuzeigende Text aus einer Datei ausgele-
sen werden, muß der Aufruf für ein Popup

msgbox popup=Dateiname

und für eine Message

msgbox msg=Dateiname

lauten. Die Erkennung, daß es sich um eine Datei handelt, erfolgt am Zeichen "/" am Anfang des
Dateinamens. Dieser Dateiname kann in Hochkommas gesetzt werden, es ist aber nicht zwingend er-
forderlich.
Wird ein Text als Message angezeigt, ist das an dem OK-Button am unteren Fensterrand erkennbar.
Bei einem Popup wird dieser Button nicht angezeigt. Beide Anzeigearten lassen sich jedoch durch
Betätigen der Tasten "HOME" oder "OK" auf der Fernbedienung schließen.

Das Verhalten der Messagebox kann über einige zuätzliche Parameter gesteuert werden:

title="Fenstertitel"

Der in Hochkommas gestellte Text wird als Titel für die angezeigte Box verwendet. Wird die-
ser Parameter nicht angegeben, verwendet das msgbox den Titel "Information". Um Platz zu spa-
ren kann die Titelzeile auch komplett ausgeschaltet werden. Das geschieht mit dem Parameter
title="none" (Kleinschreibung beachten!).

size=nn

Die Zahl "nn" wird als Fontgröße für den anzuzeigenden Text verwendet. Je größer diese Zahl
ist, um so weniger Text paßt natürlich auf die volle Bildschirmbreite. Die Fenstergröße der
Box wird dabei automatisch entsprechend der Zeilenlänge und der Zeilenanzahl gesetzt. Ohne
Parameter wird standardmäßig die Fontgröße 36 verwendet.

timeout=nn

Mit diesem Parameter kann festgelegt werden, nach welcher Zeit sich die Box von selbst wieder
schließen soll, wenn sie nicht durch einen Tastendruck auf der Fernbedienung geschlossen wird.
Ohne Parameter schließt sich die Box bei einer Message nach 5 Minuten und bei einem Popup nach
der Timeoutzeit, welche in den Neutrino-Einstellungen für die Info-Zeile festgelegt wurde. Diese
Zeit wird durch einen beliebigen tastendruck (außer OK und HOME) neu gestartet. Soll die Message-
box ohne Timeout unbegrenzt offenbleiben, ist als Wert für den Timeout "timeout=-1" anzugeben.

In der Funktion als MessageBox ("msg=...") können bis zu 24 Tasten angezeigt und die Auswahl
des Nutzers abgefragt werden. Anzahl und Beschriftung der Tasten werden über den Parameter

select="Label 1[,Label 2[,...]]"

festgelegt. Dabei können 1 bis 24 Tasten mit den entsprechenden Texten (z.B. "Label 1") erzeugt
werden. Die einzelnen Label-Bezeichner können von beliebig vielen Kommas angeführt und auch ge-
folgt werden. Ausgewertet werden nur die nichtleeren Bereiche zwischen zwei Kommas.
Die Breite der Tasten und damit auch des gesamten Fensters richtet sich nach der längsten Tas-
tenbezeichnung und der Anzahl der Tasten. Ohne Angabe des "select="-Parameters wird eine Taste
mit dem Label "OK" erzeugt.

Da bei der Übergabe aus Scripten für den Paramter "select=" bei leeren Variablen auch zwei Kom-
mas aufeinanderfolgen können, werden solche Übergaben normalerweise ignoriert. Also würden bei
einem Parameter "select=Eintrag1,,Eintrag3" zwei Buttons angezeigt werden. Im Normalfall würde
bei Auswahl von "Eintrag3" als Rückgabewert "2" übergeben werden. Soll jedoch die Zuordnung zu
den Variablen erhalten bleiben, kann mit dem Parameter

absolute=1

festgelegt werden, daß als Rückgabewert die absolute Position des Eintrages in der Select-Liste
zurückgegeben wird. Bei "Eintrag3" wäre das also "3". Der Defaultwert für "absolute" ist "0".

Um die sinnvollste Taste bereits beim Start selektieren zu können, kann mit dem Parameter

default=n

die Nummer der Taste (1..24) übergeben werden, welche unmittelbar nach Anzeige der Messagebox
selektiert sein soll und nur noch mit OK bestätigt werden braucht. Dabei ist zu beachten, daß
bei "absolute=1" auch der Defaultwert absolut abgegeben werden muß.

Um anzugeben, wieviel Tasten in einer Zeile angezeigt werden sollen, wird der Parameter

order=n

übergeben. Sind zum Beispiel 12 Tasten vereinbart und order wird mit 4 angegeben, werden 3 Reihen
zu je vier Tasten erzeugt. Dabei ist jedoch das maximal ausfüllbare Bildschirmformat zu berück-
sichtigen. Bei mehreren Zeilen kann zusätzlich zu den Links-/Rechts-Tasten mit den Hoch-/Runter-
Tasten zwischen den Zeilen navigiert werden.

Um die gewählte Taste im Script leichter auswerten zu können, kann zusätzlich zum oben beschrie-
benen Rückgabewert auch der Text der gewählten Taste über die Konsole ausgegeben werden. Das wird
mit dem Parameter

echo=n

geregelt. Ist n=1, wird statt der Versionsmeldung am Programmstart am Ende des Programms der Label
der gewählten Taste auf der Konsole ausgegeben. In diesem Fall ist die Auswertung des Ergebnisses
abweichend zu der oben beschriebenen Aufrufsyntax statt über "$?" in der Form

auswahl=`msgbox .... echo=1`

möglich. Der Label der gewählten Taste kann dann über $auswahl ausgewertet werden. Bei Timeout oder
Abbruch bleibt $auswahl leer.

Über die Mute-Taste der Fernbedienung kann die MessageBox zeitweilig ausgeblendet werden. Einmal
Drücken der Mute-Taste blendet die Box aus, ein weiterer Druck auf Mute blendet sie wieder ein.

hide=n

Was nach dem Ausblenden der MessageBox angezeigt wird, hängt vom Parameter "hide" ab. Bei 0 wird
der Druck auf die Mute-Taste ignoriert und die Box wird nicht ausgeblendet, bei 1 wird ein gelösch-
ter Bildschirm angezeigt (nur das Fernsehbild ist zu sehen), bei 2 wird der Bildschirminhalt ange-
zeigt, welcher vor dem Start der Messagebox zu sehen war (Menüs usw.). Defaultwert ist "1".
Wurde als Textparameter eine Datei übergeben, wird diese vor dem Einblenden neu eingelesen. Somit
werden während des Ausblendens in dieser Datei vorgenommene Änderungen nach dem Einblenden aktuell
angezeigt. Während die Box ausgeblendet ist, werden alle Tastendrücke außer der Mute-Taste ignoriert.
Um aus dem Script heraus überprüfen zu können, ob die MessageBox ausgeblendet ist, wird von der Mes-
sageBox für die Zeit, in der sie ausgeblendet ist, die Flagdatei "/tmp/.msgbox_hidden" erzeugt.

Um das Verhalten bei bereits Angezeigten Menüs oder Meldungen zu steuern, dient der Parameter

refresh=n

Mit n=0 werden vor dem Start der MessageBox angezeigte Menüs oder Infos gelöscht (nur die Messa-
geBox ist sichtbar) und beim Beenden der MessageBox der Bildschirm gelöscht.
Mit n=1 blendet sich die MessageBox über bereits angezeigte Infos ein, löscht den Bildschirm beim
Beenden aber komplett.
Mit n=2 werden vor dem Start der MessageBox angezeigte Menüs oder Infos gelöscht (nur die Messa-
geBox ist sichtbar), die vorher abgezeigten Infos aber beim Beenden der Messagebox wiederhergestellt.
n=3 kombiniert 1 und 2, die MessageBox blendet sich über vorher angezeigte Infos ein und stellt beim
Beenden den Bildschirmzustand wieder her, welcher vor dem Start der MessageBox aktuell war.
Dieser Parameter kann entfallen, in diesem Fall wird standardmäßig mit refresh=3 gearbeitet.

Normalerweise wird die MessageBox auf dem Bildschirm jede Sekunde aufgefrischt.
Sollte das bie bestimmten Anwendungen stören, kann dieser zyklische Refresh ausgeschaltet werden.
Dazu wird der Parameter

cyclic=0

übergeben. Damit wird die Box nur noch ein Mal beim Aufruf und der Änderung des Inhaltes einer ange-
zeigten Datei dargestellt. Der Defaultwert für cyclic ist 1.

Im Titelbereich wird standardmäßig ein Info-Icon im PNG-Format angezeigt. Es werden Icons bis zu
einer Größe von 100 x 60 angezeigt. Größere werden skaliert. Die Anzeige von eigenen Icons wird mit
icon=/Pfad_zum_Icon/mein_Icon.png angegeben.

icon=

Mit icon="none" oder icon=0  wird kein Icon angezeigt. Weitere sind "error" oder 1, "info" oder 2.


Formatierung des übergebenen Textes
-----------------------------------
Um die Darstellung des Textes ansprechender gestalten zu können, werden bestimmte Formatsteuer-
zeichen im übergebenen Text unterstützt. Allen Steuerzeichen gemeinsam ist der Beginn mit dem
Zeichen "~". Dieses kommt im normalen Text nicht vor und leitet daher immer einen Formatierungs-
befehl ein. Folgende Formatierungen können ausgeführt werden:

~l Diese Zeile auf Links-Anschlag schieben
~c Diese Zeile zentrieren
~r Diese Zeile auf Rechtsanschlag schieben
~t Tabulator
~Tnnn nachfolgenden Text auf absoluter Position nnn beginnen (nur im Messagetext zulässig)

~s Separator (eine waagerechte Linie über die gesamte Textbreite auf Zeilenmitte, halbe Schrifthöhe)
~C! Separator (wie ~s, jedoch volle Schrifthöhe)
~C!Text Separator mit Text (wie ~s jedoch wird mittig ein Text angezeigt, volle Schrifthöhe) 
~CLText Separator (rechtsbündiger Text der eine waagerechte Linie folgt, volle Schrifthöhe)
~CRText Separator (rechtsbündiger Text der eine waagerechte Linie vorangesetzt ist, volle Schrifthöhe)

~R nachfolgenden Text rot darstellen, gilt bis zum Zeilenende oder einem neuen Farbbefehl
~G nachfolgenden Text grün darstellen, gilt bis zum Zeilenende oder einem neuen Farbbefehl
~B nachfolgenden Text blau darstellen, gilt bis zum Zeilenende oder einem neuen Farbbefehl
~Y nachfolgenden Text gelb darstellen, gilt bis zum Zeilenende oder einem neuen Farbbefehl
~F nachfolgenden Text blinkend darstellen, gilt bis zum Zeilenende oder einem neuen Farbbefehl
~S nachfolgenden Text in Standardfarbe darstellen


Sonderzeichen über die Kommandozeile
------------------------------------
Da Linux keine Übergabe von Sonder- und Steuerzeichen über die Kommandozeile unterstützt, können
die wichtigsten Sonderzeichen über die Nutzung des Formatsteuerzeichens sowohl aus Scripten als
auch von der Kommandozeile dargestellt werden. Aktuell werden folgende Sonder- und Steuerzeichen
unterstützt:

~n neue Zeile (nur von der Kommandozeile)
~a ä
~o ö
~u ü
~A Ä
~O Ö
~U Ü
~z ß
~d ° (degree)


Die Wirkung der Formatierungen kann man sich anhand des beiliegenden Beispieltextes anschauen.
Die Datei "msgbox.txt" nach /tmp/ kopieren und anschließend über Telnet eingeben:

msgbox title="Beispieltext anzeigen" msg=/tmp/msgbox.txt

Der Parameter "title" kann hier natürlich auch weggelassen werden. ;-) Aber denkt bitte daran,
daß bei einem Aufruf über Telnet Neutrino auch weiterhin auf die Fernbedienung reagiert. Das
ist kein Fehler der Messagbox. Bei einem Aufruf aus einem Script heraus, welches über die Plug-
in-Verwaltung gestartet wurde, tritt dieser Effekt dann nicht mehr auf.

Wird "msgbox" mit falschen oder völlig ohne Parameter aufgerufen, wird im Log eine Liste der
unterstützten Parameter ausgegeben.
