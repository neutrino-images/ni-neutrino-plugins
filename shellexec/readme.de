Das Plugin dient zum Aufräumen des Menüs der blauen Taste. Viele dort auswähl-
bare Scripts oder Binarys werden selten benötigt und verringern nur die Über-
sichtlichkeit des Menüs. Statt dieser vielen Plugins wird nun das shellexec-
plugin in den Ordner /lib/tuxbox/plugins kopiert und die anderen Plugins kön-
nen dort gelöscht werden. Die von ihnen aufgerufenen Scripte werden nun in die
shellexec.conf eingetragen, und stehen nun als eine Art Untermenü unter dem
in der shellexec.cfg eingetragenen Namen zur Verfügung.

Auch wer selber Plugins als Script schreibt, kann dieses Plugin als Ersatz für
das ungeliebte LCD-Menü verwenden.
Wenn man nicht direkt ein weiteres Script vom Menü aufrufen lassen will, kann
man sich natürlich auch den vom Benutzer ausgewählten Menüpunkt in eine Datei
schreiben lassen:

für Menüpunkt 1 z.B. die Aktion "echo 1 > /tmp/menu.res" eintragen

und diese Datei anschließend mit seinem Script auswerten. Somit kann man
seine eigenen Plugins mit einem komfortableren Menü ausstatten. Die Dateien
shellexec.so und shellexec.cfg werden in diesem Fall nicht benötigt, da der Auf-
ruf des Plugins ja vom Script aus erfolgt. In diesem Fall müssen jedoch in der
.cfg des aufrufenden Scripts die Einträge "needfb=" und "needrc=" auf "1" ge-
setzt werden, damit während der Aktivität des Menüs nicht auch Neutrino auf
die Tasten der Fernbedienung reagiert.

Um auch mehrere Konfigurationsmenüs gleichzeitig auf der Box halten zu können,
kann die shellexec sowohl aus der shellexec.so als auch von der Kommandozeile
aus mit einem Parameter für die zu verwendende Konfigurationsdatei aufgerufen
werden. Der abweichende Pfad zur Config-Datei kann in der shellexec.so mit ei-
nem Hex-Editor ab Adresse 1E35H eingetragen werden. Hat man zum Beispiel mit
seinem Script eine spezielle Konfiguration als /tmp/myconfig.cfg abgespeichert,
kann bei einem Aufruf aus einem Script heraus folgender Aufruf verwendet werden:

shellexec /tmp/myconfig.conf

Wird kein Kommandozeilenparameter angegeben, verwendet das Plugin die Datei
/var/tuxbox/config/shellexec.conf.


Installation:

Die Verzeichnis-Struktur gibt den Ort der Dateien im Image eigentlich schon vor,
also shellexec.cfg und shellexec.so (Rechte auf 755) nach /lib/tuxbox/plugins/.
shellexec nach /var/plugins und shellexec.conf nach /var/tuxbox/config. shellexec
braucht die Rechte 755.
Wer die beiliegende shellexec.conf testen möchte, benötigt dazu noch das Script
"operations" in /var/plugins/, ebenfalls mit den Rechten 755.

In der shellexec.cfg kann man eintragen, unter welchem Namen das Plugin in der
Pluginliste der blauen Taste angezeigt werden soll. Umlaute sind hier nicht zu-
lässig (liegt aber am Neutrino).

Die Einträge in der shellexec.conf legen fest, welche Aktionen ausgeführt werden
sollen. In dieser Datei sind Umlaute zulässig.

Die Höhe des Menüfensters wir mit dem Eintrag:

HIGHT=

festgelegt. Kleinster Wert und auch Defaultwert ist aus Kompatibilitätsgründen
zu vorherigen Versionen des FlexMenüs eine Höhe von 380 Pixeln. Der Maximalwert
ergibt sich aus der Höhe des in den Videoeinstellungen festgelegten Bildbereiches.

Auch die Breite des Menüfensters, welche durch den Eintrag:

WIDTH=

festgelegt wird, beträgt minimal und defaultmäßig 400 Pixel und maximal die in
den Videoeinstellungen festgelegte Fensterbreite.

Für die Auswahl des Textfonts ist der Eintrag:

FONT=/share/fonts/micron_bold.ttf

zuständig. Hier kann der gewünschte im Image verfügbare Font eingetragen werden.
Wird dieser Eintrag weggelassen, wird standardmäßig der Font "pakenham.ttf" ver-
wendet, welcher in jedem Image vorhanden ist.

Um bei einem wählbaren Font die Textgröße anzupassen, ist der Eintrag:

FONTSIZE=19

entsprechend zu modifizieren. Dieser Wert hängt stark vom verwendeten Font ab.
Wurde der Eintrag "FONT=" bereits weggelassen, sollte auch dieser Eintrag nicht
verwendet werden, damit das Plugin den zum "pakenham.ttf" passenden Wert von 30
verwendet.

Der Eintrag

PAGING=1

legt fest, daß der Auswahlbalken beim Bewegen über die Hoch-/Runter-Tasten bei
Erreichen des Seitenendes auf die nächste Seite überspringt. Mit dem Parameter
"0" bewegt sich der Balken nur innerhalb der aktuellen Seite, springt also bei
Erreichen des Seitenendes wieder an den Seitenanfang und umgekehrt.

Um die Anzahl der Zeilen festzulegen, welche pro Menüseite angezeigt werden sol-
len, kann der Parameter

LINESPP=

verwendet werden. Standardmäßig wird von 10 Zeilen je Seite ausgegangen. Sollen
mehr Zeilen dargestellt werden, ist auch die Fontgröße entsprechend zu verkleinern,
damit sich die Zeilen nicht überlappen.

Um den Aufbau komplexerer Menüs zu beschleunigen, kann das Plugin nach seinem Start
den sectionsd von Neutrino anhalten oder auch komplett beenden. Die nun freigewordene
Prozessorperformance steht nun dem Plugin zur Verfügung. Beim Beenden wird der sec-
tionsd natürlich wieder gestartet. Ob der sectionsd während der Laufzeit beendet
werden soll, kann mit einer "1" für Beenden und einer "2" für das Anhalten hinter dem
Parameter

KILLEPG=

festgelegt werden. Der Nachteil des Beendens des sections gegenüber dem bloßen Anhalten
liegt darin, daß nach dem Beenden des FlexMenüs der sectionsd erst wieder alle Daten
neu sammeln muß. Daher ist das Anhalten mit "2" die bessere Wahl.

Da die Uhr systembedingt beim Aufruf von Plugins nachgeht, kann das FlexMenü beim Be-
enden die Uhrzeit wieder korrigieren, sofern eine Internetverbindung möglich ist. Dazu
wird standardmäßig der Server von time.fu-berlin.de verwendet. Dieses Verhalten kann
mit dem Parameter

TIMESERVICE=

gesteuert werden. Ist dieser Eintrag gar nicht vorhanden, wird, wie gesagt, der Berliner
Zeitserver verwendet. Soll ein anderer Server verwendet werden, ist er hinter dem "="
einzutragen. Soll gar keine Zeitsynchronisation verwendet werden, ist hinter dem "=" ent-
weder "NONE" oder gar nichts einzutragen (nur Zeilenumbruch).

Ein Menü (auch das Hauptmenü) wird mit dem Eintrag:

MENU=Menüname[,Message][,ICON=filename]

eingeleitet, wobei für "Menüname" einzutragen ist, wie das Menü auf dem Bildschirm
und im LCD-Display genannt werden soll.
Sollen Menüs abhängig von vorhandenen Flag-Dateien (z.B. /tmp/.flag) angezeigt werden,
ist das über die folgenden Schlüsselwörter möglich:

MENUDON=Menüname,Dateiname[,Message][,ICON=filename]

wird nur als Menü angezeigt, wenn die Datei "Dateiname" vorhanden ist. Hingegen wird

MENUDOFF=Menüname,Dateiname[,Message][,ICON=filename]

nur angezeigt, wenn die Datei "Dateiname" nicht vorhanden ist. Somit kann das Menü
abhängig von Systemzuständen aufgebaut werden. Ein Beispiel dazu ist in der beilie-
genden shellexec.conf zu finden.

Sollen Menüs abängig von Ergebnissen von Shell-Kommandos angezeigt werden, ist das
über die folgenden Schlüsselwörter möglich:

MENUSON=Menüname,Shell-Kommando[,Message][,ICON=filename]

wird nur als Menü angezeigt, wenn das eingetragene Shell-Kommando Erfolg (also 0) rück-
meldet

MENUSOFF=Menüname,Shell-Kommando[,Message][,ICON=filename]

wenn das eingetragene Shell-Kommando Fehler (also -1) rückmeldet. Somit kann das Menü
z.B. mit dem "grep"-Kommando abhängig vom Inhalt von Dateien aufgebaut werden. Ein Bei-
spiel dazu ist in der beiliegenden shellexec.conf zu finden.

Jede Menüebene wird immer mit dem Schlüsselwort

ENDMENU[=Aktion beim Schliessen des Untermenüs[,Bedingung für Aktionsausführung]]

beendet. Optional kann angegeben werden, ob beim Schließen des jeweiligen Untermenüs
noch eine Aktion (Shell-Kommando) ausgeführt werden soll. Wird keine Aktion angegeben,
wird das Untermenü einfach geschlossen. Eine angegebene Aktion ohne Bedingung wird bei
jedem Schließen des Untermenüs ausgeführt. Optional kann noch ein Shell-Kommando als
Bedingung angegeben werden. Dann wird die Aktion nur ausgeführt, wenn das Ergebnis des
als Bedingung angegebenen Shell-Kommandos "0" ist. Die Anwendung dieser Funktion ist in
der "shellexec.conf" in Verbindung mit der "operations" demonstriert.

Der Zusatz ",Message" wird bei Menüs verwendet, welche sehr lange für ihren Aufbau benötigen.
Mit der Anzeige dieses wählbaren Textes kann der Benutzer auf die Verzögerung hingewiesen
werden. Diesen Text aber bitte nicht zu lang wählen, es steht nur eine Zeile für die Darstel-
lung zu Verfügung.

Um in der Titelzeile eines Menüs ähnlich wie bei den Neurtrino-Menüs ein Icon anzeigen zu
lassen, welches die Funktion des Menüs besser verdeutlicht, kann optional der Name eines
Icons (,ICON=filename) angegeben werden. Die Icons müssen vom Format "*.raw" sein und kön-
nen z. Bsp. mit dem "Neutrino Graphics Creator" erzeugt werden. Als Beispiel kann man sich
das Icon "/share/tuxbox/neutrino/icons/mainmenue.raw" anschauen. (Erst ab 2.38 implementiert)
Menütitel werden normalerweise, wie in den Neutrino-Menüs auch, auf Linksanschlag positioniert.
Soll der Titel aus optischen Gründen zentriert dargestellt werden, ist dem Menünamen ein
Unterstrich ( _ ) voranzustellen. Der Unterstrich selbst wird nicht angezeigt, sorgt aber
für die Zentrierung des Menütitels.

Nun zu den eigentlichen Menüeinträgen der Aktionen:

ACTION=Anzeigename im Menü,auszuführende Aktion[,Message]

Die auszuführende Aktion kann ein direktes Shell-Kommando sein (rm /tmp/file)
oder der Aufruf eines Scriptes oder einer Binary. Die aufzurufenden Scripte müssen
natürlich die Rechte 755 haben.

Sollen Aktionseinträge abhängig von vorhandenen Flag-Dateien (z.B. /tmp/.flag) ange-
zeigt werden, ist das über die folgenden Schlüsselwörter möglich:

DEPENDON=Anzeigename im Menü,[auszuführende Aktion],Dateiname[,Message]

wird nur im Menü angezeigt, wenn die Datei "Dateiname" vorhanden ist. Hingegen wird

DEPENDOFF=Anzeigename im Menü,[auszuführende Aktion],Dateiname[,Message]

nur angezeigt, wenn die Datei "Dateiname" nicht vorhanden ist. Somit kann das Menü
abhängig von Systemzuständen aufgebaut werden. Ein Beispiel dazu ist in der beilie-
genden shellexec.conf zu finden.

Sollem Aktionseinträge abängig von Ergebnissen von Shell-Kommandos angezeigt werden,
ist das über die folgenden Schlüsselwörter möglich:

SHELLRESON=Anzeigename im Menü,[auszuführende Aktion],Shell-Kommando[,Message]

wird nur im Menü angezeigt, wenn das eingetragene Shell-Kommando Erfolg (also 0) rück-
meldet

SHELLRESOFF=Anzeigename im Menü,[auszuführende Aktion],Shell-Kommando[,Message]

wenn das eingetragene Shell-Kommando Fehler (also -1) rückmeldet. Somit kann das Menü
z.B. mit dem "grep"-Kommando abhängig vom Inhalt von Dateien aufgebaut werden. Ein Bei-
spiel dazu ist in der beiliegenden shellexec.conf zu finden.

Einträge in eckigen Klammern können bei Bedarf entfallen. Wird [auszuführende Aktion]
nicht eingetragen, wird der Eintrag zwar angezeigt, wenn die Anzeigebedingungen erfüllt
sind, dies jedoch in der Farbe des Kommentartextes und der Eintrag ist auch nicht aus-
wählbar. Ein solcher Eintrag kann zum Beispiel als systemabhängige Informationszeile
verwendet werden.
Der Zusatz ",Message" wird bei Aktionseinträgen verwendet, welche nach Ausführung zum
Menü zurückkehren. Normalerweise wird während der Ausführung der Aktion ein Meldungs-
fenster mit der Nachricht "Bitte warten" angezeigt. Statt dessen kann der als "Message"
eingegebene Text in diesem Fenster angezeigt werden. Diesen Text aber bitte nicht zu
lang wählen, es steht nur eine Zeile für die Darstellung zu Verfügung.

Sollen die Einträge, welche normalerweise nicht angezeigt werden würden, zwar angezeigt
werden aber nicht auswählbar sein (Darstellung erfolgt in der Farbe der Info-Einträge),
so ist für den entsprechenden Eintrag ein "+" vor den Anzeigenamen zu schreiben. Das
kann angewendet werden, um die Seitenaufteilung eines Menüs immer gleich zu halten.
Soll dem inaktiven Eintrag auch ein Shortcut-Eintrag vorangestellt werden, um z.B. die
Farbtasten immer gleich zu belegen, ist statt des "+" ein "-" zu verwenden. Eine Kombi-
nation von "+" bzw. "-" und den unten beschriebenen "*", "!", "§" und "&" ist zulässig.

Zur besseren Strukturierung des Menüs können auch Info-Zeilen eingefügt werden. Diese
werden im Menü in kleinerer Schrift und mit der Farbe des für die Menüs eingestellten
inaktiven Textes dargestellt. Diese Einträge sind im Menü nicht anwählbar. Mittels die-
ser Einträge können auch Info-Seiten erstellt werden, welche nur Kommentareinträge ent-
halten. Erstellt werden sie über den Eintrag:

COMMENT=Anzeigename im Menü

Wird ein leerer Info-Eintrag mit Unterstreichung angelegt:

COMMENT=*

wird der Strich nicht unterhalb der Zeile sondern mittig dargestellt, um eine gleich-
mäßige Verteilung der Einträge zu gewährleisten.

Menüs und Aktionseinträge können dabei beliebig gemischt werden. Zur Unterscheidung
von Menüs und Aktionen werden Menünamen auf dem Bildschirm mit einem vorangestellten
">" angezeigt.
Steht vor dem Anzeigenamen ein "*", wird im Menü unterhalb dieses Eintrages ein Trenn-
strich gezogen. Ab der Version 2.38 wurde ein zusätzlicher Formatierungsschalter "!"
eingeführt. Dieser bewirkt bei normalen Einträgen das Erzeugen eines größeren Abstan-
des zwischen den Einträgen und der Trennzeile, um die Optik der der Neutrino-Menüs an-
zupassen. Da dabei jedoch eine zusätzliche halbe Zeile verbraucht wird, muß selbst da-
rauf geachtet werden, daß die maximale Höhe des Menüs nicht überschritten wird. Faust-
formel: ein "!" in einem normalen Eintrag benötigt eine halbe Zeile zusätzlich, ein
Eintrag in der Form "COMMENT=!" ohne Kommentartext spart eine halbe Zeile ein. Eine
Sonderstellung nimmt der Ausdruck "COMMENT=!Kommentartext" ein. Diese Formatierung ist
der Menüunterteilung mit Überschrift der Neutrino-Menüs nachempfunden. Der Kommentartext
wird also in normaler Größe in Kommentarfarbe zentriert in der Zeile positioniert und
vor und hinter ihm wird mittig eine waagerechte Linie in Kommentarfarbe gezogen.

Das Plugin beendet sich nach dem Aufruf der eingetragenen Aktion nor-
malerweise selbst. Soll es sich nicht selbstständig schließen, ist vor dem Anzeige-
namen ein "&" einzutragen. Das Plugin wartet dann, bis die aufgerufene Aktion beendet
ist und steht dann für weitere Aktionen zur Verfügung.
Viele Plugins (z.B. der Werbezapper) verwenden die Fernbedienung und den Framebuffer.
So lange sie über die Plugin-Verwaltung von Neutrino aufgerufen werden, gibt es keine
Probleme. Beim Aufruf über das Menü-Plugin kommt es jedoch zu Reaktionen von Neutrino
auf die Fernbedienung. In diesem Fall ist statt des "&" der Schalter "§" zu verwenden.
Das Menü-Plugin wartet dann so lange, wie das aufgerufene Plugin läuft und blockiert
für diese Zeit die Fernbedienung und den Framebuffer für Neutrino. Somit treten auch
keine gegenseitigen Beeinflussungen mehr auf. Wird das aufgerufene Plugin beendet, be-
endet sich auch das Menü-Plugin. Auch die Kombination "*&" oder "*§" vor dem Anzeige-
namen ist zulässig für einen unterstrichenen Eintrag, bei dem das Menü nicht selbst-
ständig beendet werden soll. Auch der Eintrag "&*" oder "§*" ist zulässig.

Zur Hervorhebung von Menü- und Aktionseinträgen können diesen auch andere als die im
Neutrino eingestellten Standardfarben zugewiesen werden. Das geschieht durch Farbsteu-
erzeichen innerhalb des Textes. Eingeleitet wird die Farbsteuerung mit dem Zeichen "~"
gefolgt von dem Buchstaben für dei Farbauswahl. Folgende Farben sind möglich:

~R nachfolgenden Text rot darstellen, gilt bis zum Textende oder einem neuen Farbbefehl
~G nachfolgenden Text grün darstellen, gilt bis zum Textende oder einem neuen Farbbefehl
~B nachfolgenden Text blau darstellen, gilt bis zum Textende oder einem neuen Farbbefehl
~Y nachfolgenden Text gelb darstellen, gilt bis zum Textende oder einem neuen Farbbefehl
~S nachfolgenden Text wieder in Standardfarbe darstellen

Innerhalb einer Zeile können auch mehrere Farbsteuerzeichen für unterschiedliche Text-
teile verwendet werden. Folgen zwei Farbsteuerzeichen unmittelbar aufeinander, gilt das
letze. Das erste Farbsteuerzeichen darf erst hinter eventuellen Steuerschaltern (*&§+-)
stehen. Kommentare, inaktive Zeilen und die Farbe des Textes wenn der Auswahlbalken über
ihm steht, werden von den Farbsteuerzeichen nicht beeinflußt.
Für eine von der Zeichenbreite der Truetypefonts unabhängige Formatierung kann das Tabu-
latorsteuerzeichen "~T" verwendet werden. Das nächste auf dieses Steuerzeichen folgende
Zeichen wird auf einer Position dargestellt, welche das nächste Vielfache von 40 Pixeln
nach dem letzten bis dahin geschriebenen Zeichen ist.


Zum Einbinden dynamisch erzeugter Menüteile kann das Kommando

INCLUDE=Dateiname

innerhalb einer Konfigurationsdatei verwendet werden. Erkennt das Plugin solch einen Ein-
trag, wird diese Zeile durch den Inhalt der angegebenen Datei "Dateiname" ersetzt. So könn-
nen andere Plugins Menü- oder Informationseinträge z.B. dynamisch in /tmp/ erzeugen und so
das Aussehen des Menüs beenflussen. Existiert die angegebene Datei nicht, wird der Eintrag
ignoriert. Auch die mit "INCLUDE" eingebundene Datei darf "INCLUDE"-Einträge enthalten. Das
ist bis zu einer Verschachtelungstiefe von 16 Ebenen möglich.

Sonderzeichen über die Kommandozeile
------------------------------------
Da Linux keine Übergabe von Sonder- und Steuerzeichen über die Kommandozeile unterstützt,
welche ja zum erstellen dnamisch erzeugter Konfigurationen verwendet wird, können die wich-
tigsten Sonderzeichen über die Nutzung des Formatsteuerzeichens sowohl aus Scripten als auch
von der Kommandozeile dargestellt werden. Aktuell werden folgende Sonder- und Steuerzeichen
unterstützt:

~t Tabulator
~Tnnn absoluter Tabulator auf Position nnn (in Pixel), nnn muß immer dreistellig sein
~a ä
~o ö
~u ü
~A Ä
~O Ö
~U Ü
~z ß
~d ° (degree)

Um diese Steuerzeichen zum Beispiel für die Übergabe über die Kommandozeile an ander Plugins
beim Einlesen der Config beizubehalten, kann der Text, dessen Steuerzeichen beibehalten wer-
den sollen, in einfache Hochkommas gesetzt werden. Der Text "Spa~z" würde nach dem Einlesen
also zu "Spaß" umgewandelt werden, 'Spa~z' hingegen bleibt unverändert.

Sollten Programme oder Webseiten den Text als Unicode liefern, kann das FlexMenü auch die
wichtigsten Umlaute daraus darstellen (auch bei neueren Images mit rigoroserem UFT8-Handling).
Folgende Unicode-Zeichen werden unterstützt:

0xC3+0xA4 ä
0xC3+0xB6 ö
0xC3+0xBC ü
0xC3+0x84 Ä
0xC3+0x96 Ö
0xC3+0x9C Ü
0xC3+0x9F ß

Um auch im Anzeigenamen Kommas verwenden zu können, welche normalerweise als Trennzeichen
zwischen den einzelnen Eintragsteilen verwendet werden, kann man den Text, welcher Kommas
enthält, in einfache Hochkommas einschließen. Dadurch werden die Kommas mit im Menü angezeigt.


Bei mehr als "LINESPP" Einträgen wird ein Scrollbalken eingeblendet und mittels der Rechts-/
Linkstasten kann im Menü jeweils eine Seite vor-/zurückgeblättert werden.
Mit der Home-Taste wird kehrt man zur vorherigen Menüebene zurück. In der obersten Menü-
ebene beendet Home das Plugin. Mit der Standby-Taste kann das Plugin aus jeder Menü-Ebene
heraus beendet werden.
Sollte gerade etwas Interessantes gezeigt werden, was durch das Menü verdeckt wird, kann man
das Menü durch einen kurzen Druck auf die Mute-Taste der Fernbedienung ausblenden. Das Plugin
bleibt aber im Hintergrund aktiv und kann durch einen erneuten Druck auf die Mute-Taste wieder
eingeblendet werden. Ist das Menü ausgeblendet, werden alle Tasten außer "Mute" ignoriert.
