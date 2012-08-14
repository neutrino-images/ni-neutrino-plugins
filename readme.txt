####################################################################################
####                 New-Tuxwetter Version 3.54
####            Aktuelle Wetterinfos und Wettervorhersage
####                    Bugreport und Anregungen im Board:
####       http://www.dbox2-tuning.net/forum/viewforum.php?f=27&start=0
####      Das New-Tuxwetter-Team: SnowHead, Worschter, Seddi, Sanguiniker
####################################################################################

ACHTUNG: Bei allen Versionen die älter als die Version 2.30 sind, funktionieren auf-
grund einer Formatumstellung des Wetterservers die Vorschauen nicht mehr!!

Vorraussetzung:
---------------

Die Vorraussetzung für die korrekte Funktion des New-Tuxwetter-Plugins, ist eine
funktionierende Internetverbindung. Diese kann entweder über einen Router oder über 
einen PC mit ICS (Internet Connection Sharing = Internetverbindungsfreigabe) erfolgen. 
Laufen schon andere Plugins mit Internetanbindung (z.B. Tuxmail, Newsticker etc.),
sollte das Wetterplugin normalerweise ebenfalls funktionieren.
Nutzer eine Proxservers können diesen dem Plugin mit folgenden Einträgen in der Datei
tuxwetter.conf bekanntmachen

 ProxyAdressPort=ProxyAdresse:ProxyPort
 ProxyUserPwd=Username:Passwort

 Beispiel:
 ProxyAdressPort=192.168.0.128:8080
 ProxyUserPwd=username1:passwort1

Die einzigen Einstellungen müssen in der "tuxwetter.conf" vorgenommen werden.

Mit dem Parameter 

 SplashScreen=1

legt man fest, daß der Startbildschirm angezeigt werden soll. Mit dem Parameter 0 ent-
fällt der Startbildschirm. Geschlossen wird der Startbildschirm mit der OK-Taste.
Defaulteinstellung ist 1


Mit dem Parameter

 ShowIcons=1

kann ausgewählt werden, ob in den Textanzeigen der Wetterdaten zusätzlich die aktuellen
Wettersymbole eingeblendet werden sollen. Da diese Symbole wegen ihrer Größe vom Server
heruntergeladen werden, empfiehlt es sich, bei langsamen Internetverbindungen diese Funk-
tion mit dem Wert 0 zu deaktivieren
Defaulteinstellung ist 0

Ob die Einheiten metrisch oder nichtmetrisch angezeigt werden, legt der Parameter
  
 Metric=1
  
fest. Mit der Defaulteinstellung "1" werden Einheiten, Zeiten und Datum metrisch 
dargestellt.


Der Parameter

 InetConnection=ISDN

teilt dem Plugin mit, daß der Internetzugang per ISDN erfolgt. Statt ISDN kann auch ANALOG
eingetragen werden. Für DSL ist kein Eintrag notwendig (default). Anhand dieses Parameters
werden beim Download von Dateien die Timeouts für Verbindungsaufnahme und Gesamtdownload-
Zeit sowie die Dateigröße berechnet, ab welcher der Fortschrittsbalken im LCD angezeigt wird.

Wer viele Web-Cams auf Home-PC's einbindet, kann mit dem Parameter

  ConnectTimeout=nn
  
die Timeoutzeit für eine Verbindungsaufnahme zusätzlich noch einmal spezifizieren, um bei
abgeschalteten PC's nicht zu lange auf eine Fehlermeldung warten zu müssen. nn gibt die
Anzahl in Sekunden an, welche maximal bis zum Etablieren der Verbindung gewartet werden
soll. Da New-Tuxwetter bei nicht erfolgter Verbindung einen zweiten Verbindungsversuch un-
ternimmt, ist die Wartezeit bis zur Fehlermeldung also nn*2 Sekunden.


Wer einen eigenen Account bei weather.com hat, kann seine eigenen Zugangsdaten verwenden,
falls der public-Zugang wegen zu häufigem Aufruf mal deaktiviert werden sollte:

ParterID=dddddddddd
LicenseKey=hhhhhhhhhhhhhhhh

Registrieren kann man sich hier: http://www.weather.com/services/xmloap.html

Die bis hier beschriebenen Parameter können auch separat in einer Datei "tuxwetter.mcfg" ge-
halten werden, um eine schnelle Konfiguration durch das Flexible Menü-Plugin "Shellexec" zu
ermöglichen. Existiert eine Datei "/var/plugins/tuxwet/tuxwetter.mcfg", haben die Einträge
in dieser Datei Vorrang vor den Einträgen in der tuxwetter.conf.


Nun sind die Städte einzutragen, für welche man die Wetterabfrage auswählen können möchte. 
Die Stadtnamen und deren Codes sind in der beiliegenden Datei "Ortscodes.txt" gelistet.

Der Eintrag für die Städte erfolgt in der Form: 
    Stadt=Stadtname_für_TV_Anzeige,Stadtcode
z.B.:
    Stadt=Mönchengladbach,GMXX0086

Wer seine gewünschte Stadt nicht in der Datei findet, kann man im Browser eingeben: 
http://xoap.weather.com/search/search?where=StadtName

Bsp:
http://xoap.weather.com/search/search?where=dresden

Antwort:
 <?xml version="1.0" encoding="ISO-8859-1" ?> 
- <!-- This document is intended only for use by authorized licensees of The Weather Channel...
  --> 
- <search ver="2.0">
  <loc id="GMXX0025" type="1">Dresden, Germany</loc> 
  <loc id="USKS0157" type="1">Dresden, KS</loc> 
  <loc id="USME0110" type="1">Dresden, ME</loc> 
  <loc id="USNY0396" type="1">Dresden, NY</loc> 
  <loc id="USOH0268" type="1">Dresden, OH</loc> 
  <loc id="USTN0146" type="1">Dresden, TN</loc> 
  </search>

Der Stadtcode für Dresden wäre demnach GMXX0025. Wird keine Stadt zurückgegeben, sind für die
angefragte Stadt keine Wetterdaten verfügbar. Dann muß man auf eine Stadt in der Umgebung aus-
weichen.

Eine weitere Möglichkeit Städtecodes zu finden ist, auf der Seite

http://de.weather.com/search/search?where=deutschland&what=WeatherCity

eine der aufgeführten Städte zu wählen (nicht über die Suche!!!)
Die Adressleiste des aufgerufenen Fensters enthält den Stadtcode der benötigt wird.
Es werden nur Städte mit dem Code GMXX0001 bis GMXX0280 unterstützt.
Ist die gewünschte Stadt nicht in dem Bereich, so steht auf der Seite direkt unter
dem Ort die Stadt Wetterstation von der die Daten kommen (z.B. wie Stuttgart).
Dann sucht euch dafür den Stadtcode, denn die Daten sind identisch.

Der Aufbau der Menüs erfolgt über die Einträge "MENU=" als Anfangskennung und "ENDMENU" als
Endekennung. Diese können beliebig tief verschachtelt und auch mit normalen Einträgen gemischt
werden. Im einfachsten Fall könnte "MENU=New Tuxwetter" am Anfang und "ENDMENU" am Ende der
Liste stehen. Mindestens eine Menüebene ist zwingend notwendig. Innerhalb einer aktuellen Me-
nüseite aufrufbaren Untermenüs sind in der Anzeige durch ein vorangestelltes ">" gekennzeichnet.
Zur optischen Trennung der Einträge kann vor den "Anzeigetext im Menü" ein "*" gesetzt werden.
Unterhalb eines solchen Eintrages wird ein Trennstrich im Menü gezogen.
Um die Darstellung der Namen der Menüeinträge ansprechender gestalten zu können, werden Farb-
steuerzeichen im übergebenen Text unterstützt. Allen Steuerzeichen gemeinsam ist der Beginn 
mit dem Zeichen "~". Dieses kommt im normalen Text nicht vor und leitet daher immer einen Farb-
befehl ein. Folgende Farben werden unterstützt:

  ~R    nachfolgenden Text rot darstellen, gilt bis zum Textende oder einem neuen Farbbefehl
  ~G    nachfolgenden Text grün darstellen, gilt bis zum Textende oder einem neuen Farbbefehl
  ~B    nachfolgenden Text blau darstellen, gilt bis zum Textende oder einem neuen Farbbefehl
  ~Y    nachfolgenden Text gelb darstellen, gilt bis zum Textende oder einem neuen Farbbefehl
  ~S    nachfolgenden Text in Standardfarbe darstellen

Das Menü kann um die Anzeige zusätzlicher, selbst auswählbarer JPG-, PNG- und GIF-Bilder aus 
dem Internet erweitert werden. Dazu muß die vollständige URL des anzuzeigenden Bildes bekannt 
sein. Um dieses Bild mit in das Funktionsmenü aufzunehmen, ist folgendes in die tuxwetter.conf ein-
zutragen (vor und hinter dem Komma darf kein Leerzeichenstehen!):

 PICTURE=Anzeigetext im Menü,vollständige URL

Der Text zwischen "=" und "," wird im Funktionsmenü zur Auswahl angezeigt, die URL muß nicht er-
läutert werden. Beispiel:

 PICTURE=Temperaturen aktuell,http://image.de.weather.com/web/maps/de_DE/temperature/current/germany_temp_curr_720_de.jpg

Ist aus der Bildadresse kein Bildtyp erkennbar, muß dieser zusätzlich mit angegeben werden. Das er-
folgt durch Voranstellen von |JPG|, |GIF| oder |PNG| vor die Bildadresse. Beispiel:

 PICTURE=Stauwarnung Hessen,|GIF|http://www.swr3.de/info/verkehr/verkehr_images.php?img=M05
 
Da man auch Webcams anzeigen kann, welche ihr Bild in bestimmten Abständen aufrischen, kann
man New-Tuxwetter auch anweisen, das angezeigte Bild in einem vorgebbaren Intervall selbst-
ständig neu zu laden, ohne daß eine Taste gedrückt werden muß. Dazu ist eine Erweiterung des
oben beschriebenen Bildtyps um die Zahlenangabe des Updateintervalls in Sekunden erforderlich.
Der Bildtyp muß in diesem Fall also zwingend angegeben werden. Das folgende Beispiel frischt
das angezeigte Bild aller 30 Sekunden auf:

 PICTURE=Empuria-Brava,|JPG30|http://www.empuriabrava.tv/tresor/strapro.jpg

Manche Images haben in ihrer URL eine eindeutige Zeitangabe. Um diese Bilder auch ansehen zu 
können bietet Tuxwetter die Möglichkeit Platzhalter einzusetzen die zum Zeitpunkt des Aufrufs 
durch aktuelle Zeit und Datum ersetzt werden. Weiter besteht die Möglichkeit, mittels Operato-
ren die Zeit zu beeinflussen, um zum Beispiel gewisse Update-Zyklen exakt treffen zu können. 
Ausserdem besteht die Auswahl zwischen MESZ/MEZ und UTC.

Das generelle Format eines Platzhalters besteht aus dem Startzeichen "|", optionalen Operatoren,
einem optionalen Offset und den Formatzeichen: |[LNR][[-]1..99999]Format

Formatzeichen

D : Tag
M : Monat
Y : Jahr
h : Stunde
m : Minute
s : Sekunde

Die Anzahl der Formatzeichen bestimmt die Anzahl der Stellen mit der die Formatzeichen ersetzt 
werden. Beispiel:

"D"   liefert bei Tag 1-9 eine einstellige Ausgabe "1" ... "9" wird die Zahl zweistellig wird 
      auch die Ausgabe zweistellig.

"DD"  liefert bei Tag 1-9 die Ausgabe "01" ... "09" ab dann normal weiter.
"DDD" liefert eben generell eine dreistellige Ausgabe "001" ... "031"
usw.

Eine Ausnahme bildet hier das Jahr. Es wird ausser bei vierstelliger Eingabe immer die Zahl ohne 
das Jahrtausend liefern (Beispiel 2004)

"Y"     = "4"
"YY"    = "04"
"YYY"   = "004"
"YYYY"  = "2004" ! Nur hier wird das Jahrtausend mit ausgegeben!
"YYYYY" = "00004"

Operatoren:

"L" : Local Time (bewirkt, daß die lokale Zeit (also MEZ oder MESZ) als Zeitbasis verwendet wird.
      Ohne diesen Operator wird UTC verwendet. Dieser Operator muß nur einmal vorkommen und wirkt
      dann auf alle Zeitangaben
"R" : gefolgt von einer Zahl rundet den zugehörigen Platzhalter auf die Zahl oder deren Vielfaches.
"N" : gefolgt von einer Zahl bewirkt den Abzug der Zahl von dem zugehörigen Platzhalter ohne daß 
      diese ausgegeben wird. Ist zum Beispiel notwendig, wenn anschließend noch gerundet werden soll.
"15": gemeint ist eine beliebige Zahl die dann vom zugehörigen Platzhalter abgezogen wird. Alle abzu-
      ziehenden Werte in der gesamten Adresse werden zunächst gemeinsam von der aktuellen Zeit abgezo-
      gen und erst dann wird mit der Ersetzung begonnen. So kann zum Beispiel der Abzug von zwei Mi-
      nuten, wenn es eine Minute nach der vollen Stunde ist, auch die Stunde verringern. Das gilt für
      alle Zeitwerte. WIrd hier eine negative Zahl (Bsp. -15) angegeben, wird diese Zeit zur aktuellen
      Zeit addiert, um Bilder mit einem Zeitstempel, welcher der aktuellen Zeit vorauselt, anzeigen zu
      können.
      
Da das ganze doch etwas trocken ist, mal ein paar Beispiele:

Wir nehmen an, es ist der 02.01.2005 um 03:16:25 MESZ

|YYYY|MM|DD|hh|mm|ss                                20050102011625  // Stunde = 01 (UTC)
|LYYYY|MM|DD|hh|mm|ss                               20050102031625  // Stunde = 03 (MESZ)
|YYYY|MM|2DD|2hh                                    2004123023      // 2 Tage und 2 Stunden abgezogen
|1hh|R15mm                                          0015            // 1 h abgezogen, Runden auf 15 min
|1hh|N15m|R15mm                                     0000            // 1h 15 min "  , " (sichere Lösung)
|L1hh|N15m|R15mm                                    0200            //  " aber MESZ


Praxis: (ein viertelstündlich aktualisiertes Bild, Datum: 13.10.2004 21:16:00 MESZ)

http://www.wetteronline.de/daten/radar/dwdd/|YYYY/|MM/|DD|hh|R15mm.gif  ergibt
http://www.wetteronline.de/daten/radar/dwdd/2004/10/131915.gif

Das könnte knapp werden, da um 21:16 das Bild von 21:15 bestimmt noch nicht geuppt wurde, und würde der
Aufruf um 21:15 erfolgen, hätte der Server gar keinen Vorlauf mehr. Sicherer ist es daher, noch eine
viertel Stunde abzuziehen und dann erst zu runden:

http://www.wetteronline.de/daten/radar/dwdd/|YYYY/|MM/|DD|hh|N15m|R15mm.gif  ergibt
http://www.wetteronline.de/daten/radar/dwdd/2004/10/131900.gif

Dieses Beispiel könnt Ihr direkt verwenden.

Für Bildadressen, die sich nicht über Zeitfunktionen berechnen lassen, gibt es die Möglichkeit, diese
Adresse aus dem Quelltext der HTML-Seite extrahieren zu lassen. Dazu ist im Quelltext nach dem Bild-
namen zu suchen. Die Textstücke, die den Namen des Bildes vorn (Grenze_vorn) und hinten (Grenze_hinten)
einschließen, sollten nun bekannt sein. Um die Bildadresse ermitteln zu lassen, ist ein Eintrag in der
Form:

 PICHTML=Anzeigetext im Menü,URL_der_HTML_Seite|Grenze_vorn|Grenze_hinten

Beispiel:
HTML-Quelltext:
 ....
 </map>

 <img src="http://212.224.23.107/images/index0000046169.png"width="550" height="500" name="Karte" usemap="#Karte" border="0"/>
 </div>
     </td>
    </tr>
 ....

Eintrag in der tuxwetter.conf:

 PICHTML=Unwetter-Warnungen,http://www.unwetterzentrale.de/uwz/index.html|<img src="|" width="550" height="500" name="Karte" usemap="#Karte" border="0"/>


Achtung!! Es koennen nur JPG- und bestimmte Typen von PNG- und GIF-Bildern dargestellt werden. Da-
bei sind jedoch auch animierte GIFs möglich, deren Einzelbilder automatisch nacheinender angezeigt 
werden.

Werden auf Internetseiten interessante Texte angezeigt, kann man sich die in begrenztem Umfang auch auf dem
Bildschirm darstellen lassen. Dazu gibt es den Typ TXTHTML. In der Syntax gleich aufgebaut wie PICHTML stellt
diese Typ den zwischen den Begrenzern gefundenen Text auf dem Bildschirm dar. Dazu werden alle HTML-Tags ent-
fernt und, wenn nötig Zeilenumbrüche für die Formatierung eingefügt.


 TXTHTML=Anzeigetext im Menü,URL_der_HTML_Seite|Grenze_vorn|Grenze_hinten

Beispiel-Eintrag in der tuxwetter.conf:

 TXTHTML=Waldbrandwarnung,http://www.zamg.ac.at/dyn/warnungen/waldb.htm|<!-- Waldbrandindex gif -->|  Uhr</font> 
 
Werden in den zu analysierenden HTML-Seiten die Links auf Bilder oder andere Seiten relativ dargestellt (also
ohne Angabe einer Serveradresse), wird davon ausgegangen, daß die Links auf das Root-Verzeichnis des Servers
verweisen. Liegen die Links nicht im Root sondern im selben Verzeichnis wie die HTML-Seite, ist der Eintrag
für diese Seite mit der Adresse "httpabs://.." einzutragen.
Beispiel:
Adresse:

  http://www.mtit.at/verkehrsbilder/scripts/getlastpicture.asp?cam=61

liefert als Quelltext:

  ...
  <tr>
  <td><img src="mmobjholen.asp?id=129125&time=23.01.2005 17:00:03" width="320" height="240" border="0"></td>
  </tr>
  ...

Dabei würde das Script "mmobjholen" in "http//www.mtit.at/" erwartet werden. Es liegt jedoch in 
"http://www.mtit.at/verkehrsbilder/scripts/". Daher muß der Eintrag in der Config-Datei lauten:

  PICHTML=Auhof,|JPG|httpabs://www.mtit.at/verkehrsbilder/scripts/getlastpicture.asp?cam=61|<td><img src="|" width="320" height="240" border="0"></td>

Internetseiten oder auch Dateien auf Netzwerkfreigaben im reinen Textformat lassen sich mit dem Plugin eben-
falls darstellen. Dazu gibt es den Typ TXTPLAIN. Mit diesem Eintrag wird eine reine Textseite heruntergeladen
und angezeigt.

 TXTPLAIN=Anzeigetext im Menü,URL_der_Text_Seite


Die Wetterwarnungen des deutschen Wetterdienstes können auf separaten Textseiten dargestellt werden.
Um an die aktuellen gewünschten Adressen (URL's) für die Wetterwarnungsdaten zu kommenen, folgenderma-
ßen vorgehen.
http://www.wettergefahren.de/de/WundK/Warnungen/index.htm aufrufen. Dort auf das gewünschte Bundesland klicken,
z.B. Baden-Württemberg.
Dann regionaler Warnlagebericht anklicken, dann im folgenden Fenster auf Datei->Eigenschaften klicken.
Im Fenster Eigenschaften die Url herauskopieren. Diese Url dann mit einem Unix fähigen Editor z.B.
Ultraedit in die tuxwetter.conf einfügen. In der gleichen Zeile davor hinschreiben
TEXTPAGE=Warnlage Baden-Württemberg,
Das gewünschte Ergebnis sollte so aussehen.

TEXTPAGE=Warnlage Baden-Württemberg,http://www.wettergefahren.de/de/WundK/Warnungen/zeige.php?WL=SU00  

Um an die Wetterwarnungen für den Landkreis zu kommen, den Landkreis auf der Wetterwarnungskarte
des Bundeslandes anklicken. Ich möchte dies hier am Beispiel Reutlingen erklären. Ihr klickt in der
Wetterwarnungskarte von Baden-Württemberg auf den Landkreis Reutlingen. Dann im folgenden Fenster auf
Datei->Eigenschaften klicken. Im Fenster Eigenschaften die Url herauskopieren. Diese Url dann mit einem
Unix fähigen Editor z.B. Ultraedit in die tuxwetter.conf einfügen. In der gleichen Zeile davor hinschreiben
TEXTPAGE=Warnstatus Reutlingen,
Das gewünschte Ergebnis sollte so aussehen.

TEXTPAGE=Warnstatus Reutlingen,http://www.wettergefahren.de/de/WundK/Warnungen/zeige.php?ID=RT#O

Sollen bestimmte Programme oder Scripte aufgerufen werden, kann der Eintrag "EXECUTE=" verwendet
werden. Er führt den eingetragenen Text auf der Kommandozeile aus. Die Syntx ist:

 EXECUTE=Anzeigename im Menü,auszuführendes Kommando
 
Beispiel:

 EXECUTE=Box neu starten,reboot

Zu den Tasten:

Bei Anzeige eines Bildes kann mittels der Hoch-/Runter-Tasten zum nächsten oder vorhergehenden Bild 
gewechselt werden, ohne erst über das Menü zu gehen. Um trotzdem darüber zu informieren, welches
Bild gerade angezeigt wird, wird der Menüname des Bildes zusätzlich noch auf dem LCD-Display der Box
angezeigt. Geschlossen wird die Grafik-Anzeige mit der OK-Taste.
Ein animiertes GIF kann nach seinem Ablauf mi der Rechts-Taste erneut gestartet werden, ohne daß es 
erst noch mal aus dem Internet geladen wird. Die Links-Taste führt zum erneuten Download des letzten
Bildes. Das ist vor allem für das Betrachten von WebCam-Bildern vorgesehen.
Während des Ladens und Konvertierens von Bildern wird in der linken oberen Bildschirmecke das vom 
Pictureviewer her bekannte "Busy-Symbol", ein kleines rotes Rechteck eingeblendet, um darauf hinzu-
weisen, daß die Box beschäftigt ist.
Bei längeren Warnmeldungen (erkennbar am Zeichen ">>" in der linken unteren Ecke") kann mit der Rechts-
Taste um 5 Zeilen vor- und mit der Links-Taste um 5 Zeilen zurückgescrollt werden.

Bei Bildern größer 100 kB, wird in der 1.Zeile des LCD-Displays der Dbox ein Ladefortschrittsbalken
angezeigt. Darunter wird der Name des Bilds eingeblendet. Es konnte aber kein korrekter Zeilenumbruch
implementiert werden, da das Wetterplugin sonst zu groß geworden wäre. (Die Box ist ja kein Duden :-).)

Nach Anpassung der tuxwetter.conf und Neustart der Box steht das Plugin unter dem Menü der blauen 
Taste als "Wettervorhersage" zur Verfügung.

Wem die auf dem LCD-Display angezeigten Wettersymbole zu spartanisch sind, kann die Datei
bmps.tar.Z aus dem Ordner "alternative LCD-Symbole" ins Verzeichnis /var/plugins/tuxwet
kopieren (die alte Datei überschreiben). das ist, wie so Vieles, immer eine Geschmacksfrage.

Zur Bedienung: Die Menüs werden über die Home-Taste, die Wetter- und Grafik-Anzeigen sowohl über die
HOME- als auch über die OK-Taste geschlossen. Auch innerhalb der Datenanzeigen kann mittels der Hoch-
/Runter-Tasten zum jeweils vorhergehenden oder folgenden Eintrag gewechselt werden.
Zum vorhergenden Menü gelangt man mit der HOME-Taste. Die Standby-Taste beendet das Programm aus
allen Menüebenen heraus.

Eine Hilfebildschirm, welcher alle Tasten und deren Funktionen beschreibt, kann mit der Taste "?" 
aufgerufen werden. Auch die aktuelle Programmversion wird in der Titelzeile angezeigt. Dieser 
Hilfebildschirm wird auch mit der OK-Taste wieder geschlossen.

Da bei einigen Images das Problem auftrat, daß bei längerer Nutzung des Plugins die Uhrzeit nachging,
da der Prozessor aufgrund der Auslastung nicht mehr in der Lage war, die Berechnung der Uhrzeit wei-
terzuführen, liegt im Ordner "optionale Zeitkorrektur" ein Programm namens "swisstime". Diese Programm
holt sich von einem Schweizer Atomzeit-Server die aktuelle Zeit und setzt damit die Uhr der DBox.
Dieses Programm ist bei Bedarf in den Ordner /var/plugins/tuxwet/ zu kopieren, und mit den Rechten 755
zu versehen. Das Plugin erkennt, ob dieses Programm vorhanden ist, und ruft es dann beim Beenden des
Plugins auf. Somit wird die Uhrzeit wieder korrigiert. Wer keine Probleme mit einer nachgehenden Uhr
hat (das ist vom Image abhängig), benötigt dieses Programm nicht.

Die Datei convert.list dient der Übersetzung der englischen Texte vom Wetterserver in deutsche Texte.
Sollten da mal irgendwelche komischen Anzeigen bei der Wettervorsage stehen, postet bitte ins
Forum, damit die fehlerhaften Anzeigen korrigiert werden können.
Fehlende Übersetzungen werden in einer Liste gesammelt, welche aus dem Hauptmenü mit der DBox-Taste
angezeigt werden kann. Das erleichtert die Meldung solcher Übersetzungen im Board. Soll die Fehler-
liste (nach Korrektut der convert.list) gelöscht werden, kann das mit der roten Taste erfolgen, während
die Fehlerliste angezeigt wird.
Ab der Version 3.00 dient die Datei convert.list gleichzeitig der Lokalisierung aller angezeigten
Texte. Im unteren Teil befinden sich dafür die originalen deutschen Meldungen, gefolgt von dem Zeichen
"|". Unmittelbar danach kann man eintragen, was statt dieses Textes angezeigt werden soll. Das kann
sowohl eine Fremdsprache sein als auch eine deutsche Meldung, welche Euch besser als die originale
gefällt. Dabei aber bitte beachten, daß der neue Text bei den Meldungen für die Datenanzeige nicht länger 
als der in der Anzeige zur Verfügung stehende Platz werden sollte, da sonst die Formatierung der An-
zeige darunter leiden würde. Steht kein neuer Text hinter dem "|", wird der Originaltext verwendet.

Wer sich eine so große tuxwetter.conf zusammengestellt hat, daß Schwierigkeiten mit dem Platz auf der
Box auftauchen, kann die tuxwetter.conf auch auf den PC auslagern und mit dem Plugin über ein vorher
gemountetes Verzeichnis darauf zugreifen. Dazu kann tuxwetter sowohl aus der tuxwetter.so als auch von 
der Kommandozeile aus mit einem Parameter für die zu verwendende Konfigurationsdatei aufgerufen werden. 
Der abweichende Pfad zur Config-Datei kann in der tuxwetter.so mit einem Hex-Editor ab Adresse 1E35H 
eingetragen werden. Ist zum Beispiel das Verzeichnis /mnt/configs/ gemountet, und auf diesem befindet
sich eine tuxwetter.conf auf dem PC, wird in der tuxwetter.so ab Adresse 1E35H die Zeichenfolge 

  /mnt/configs/tuxwetter.conf
  
eingetragen, oder das Plugin so über die Kommandozeile (z.B. aus dem FlexMenü) aufgerufen:

  /var/plugins/tuxwet/tuxwetter /mnt/configs/tuxwetter.conf
  
Wird kein Kommandozeilenparameter angegeben oder wurde die als Kommandozeilenparameter angegebene Config
nicht gefunden (Verzeichnis nicht gemountet), verwendet das Plugin die Datei 

  /var/plugins/tuxwet/tuxwetter.conf.
  
Wird New-Tuxwetter zusätzlich mit einem Aktionseintrag als Kommandozeilenparameter aufgerufen, so führt
es die entsprechende Aktion sofort aus, und beendet sich wieder, wenn die Aktion abgeschlossen wurde.
Somit kann New-Tuxwetter nun auch als aus Scripten heraus aufrufbarer Bildbetrachter oder Textviewer
verwendet werden.
Beispiel:

  /var/plugins/tuxwet/tuxwetter 'PICTURE=Teletarif Bild,http://www.teltarif.de/db/blitz.gif?preis=1&ziel=Ortsgespr~ach,Fern,Mobilfunk&ve=1&blank=1&019x=0&width=249&height=200'

zeigt sofort die aktuellen Telefontarife auf dem Bildschirm an, und beendet sich nach Schließen des Bildes.
Folgende Aktionen können als Kommandozeilenparameter verwendet werden: PICTURE, PICHTML, TXTHTML,TEXTPAGE,
TXTPLAIN und EXECUTE. Der Kommandozeilenparameter ist unbedingt in einfache Hochkommasn einzuschließen,
um die Kommandozeile komplett einschließlich Leerzeichen in den ersten Parameter übergeben zu können. Da
die Kommandozeile keine Umlaute und Sonderzeichen übergeben kann, sind, wie im Beispiel, die Sonderzeichen
durch eine vorangestellte Tilde zu kennzeichnen. Folgende Sonderzeichen werden unterstützt:

  ~a    ä
  ~o    ö
  ~u    ü
  ~A    Ä
  ~O    Ö
  ~U    Ü
  ~z    ß
  ~d    ° (degree)

Um die Version von New-Tuxwetter über die Kommadozeile abzufragen, wird tuxwetter mit dem Parameter -v oder
--Version aufgerufen. In diesem Fall gibt Tuxwetter nur seine Version auf die Konsole aus und beendet sich
anschließend selbst.

Zur Konfiguration des Plugins über das Flexible Menü-Plugin (FlexMenü) befindet sich ein Unterordner mit
dem in die shellexec.conf einzufügenden Abschnitt, ein zugehöriges Script (twops, benötigt die Rechte 755)
und die zusätzlich erforderliche Config-Datei tuxwetter.mcf im Verzeichnis "Konfiguration über FlexMenü".
Thx to MailMan für die Erstellung der FlexMenü-Konfiguration.


Also, viel Spaß und viel Erfolg

Das New-Tuxwetter-Team
SnowHead, Worschter, Seddi und Sanguiniker
