Was ist input?
----------------------------------
Input ist ein Editor, welcher aus Scripten heraus aufgerufen werden kann, und das Ergeb-
nis der Eingaben durch den Nutzer über die Kommandozeile an das Script zurückgibt.
Dabei ist beim Aufruf sowohl die Festlegung des Aussehens der Eingabemaske als auch des
Typs der zu editierenden Daten möglich. Die zu editierenden Felder können bei Bedarf
auch mit Defaultwerten vorbelegt werden.

Installation
----------------------------------
Es wird nur die Datei "input" benötigt. Abhängig vom Image-Typ ist diese entweder in
/bin/ (bei JFFS-Only) oder /var/bin/ (bei CRAMFS und SQUASHFS) zu kopieren und mit den
Rechten 755 zu versehen. Nun kann sie aus eigenen Scripten heraus verwendet werden. Eine
spezielle Busybox ist für die Verwendung von "input" nicht erforderlich.


Anwendung
----------------------------------
Der Aufruf der Eingabemaske erfolgt über die Ausführung von "input" mit entsprechenden Kom-
mandozeilenparametern. Wichtig dabei ist, daß das aufrufende Script über die Plugin-Verwal-
tung von Neutrino gestartet wurde, und in der .cfg des Scriptes die Einträge "needfb=1" und
"needrc=1" stehen. Anderenfalls würde Neutrino parallel zum Editor auf die Tastendrücke der
Fernbedienung reagieren. Beim Aufruf aus dem FlexMenü ist das Script mit den Zeichen "&" oder
"§" vor dem Anzeigenamen aufzurufen. Im Folgenden werden die möglichen Parameter beschrieben.
Die Aufrufzeile sieht so aus:

input l='Layout' [t='Title'] [d='Default'] [k=Keys] [f=Frames] [c=Columns] [o=Timeout] [m=Mask] [h=BreakOnHelp]

Layout:
Der Layoutstring, welcher festlegt, welche Felder an welcher Stelle und in welchem Format
editierbar sein sollen. Eingabefelder werden durch '#' für reine Zifferneingaben und '@'
für alphanumerische Eingaben definiert. Sollen nur Hexadezimalzeichen eingebbar sein, ist
als Definitionszeichen das Zeichen '^' zu verwenden. Alle anderen Zeichen werden auf dem
Bildschirm zwar dargestellt, sind aber nicht editierbar.
In einer Zeile können maximal 25 Zeichen dargestellt werden. Ist der Layoutstring länger als
der Parameter "c" oder länger als 25 Zeichen, werden die nächsten Zeichen auf einer weiteren
Zeile dargestellt. Damit ist die Darstellunge mehrzeiliger Eingabemasken möglich.

Title:
Die Überschrift des Editorfensters. Wird dieser Parameter nicht übergeben, wird standardmäßig
der Text "Eingabe" verwendet.

Default:
Die Editorfelder können vorbelegt werden. Dabei werden die Zeichen des Defaultstrings der
Reihe nach den Eingabefeldern zugewiesen. Der Defaulstring enthält also keine Füllzeichen
wie der Formatstring sondern nur die reinen Daten.

Keys:
Dieser Parameter kann 0 oder 1 sein. Bei 1 wird im Editorfenster die Tastenbelegung für die
Eingabe von alphanumerischen Zeichen zusätzlich mit angezeigt. Mit 0 wird diese Anzeige un-
terdrückt. Defaultwert ist 0.

Frames:
Dieser Parameter kann 0 oder 1 sein. Bei 1 werden Rahmen um die Eingabefelder gezeichnet,
bei 0 werden diese Felder ohne Rahmen dargestellt. Defaultwert ist 1.

Columns:
Mit diesem Parameter wird die Anzahl der Zeichen pro Zeile festgelegt. Somit können auch
schmalere Fenster mehrzeilig dargestellt werden. Zulässig sind Werte von 1 bis 25.
Defaultwert ist 25.

Timeout:
Gerade für PIN-Abfragen kann dieser Parameter verwendet werden. Er legt die Zeit fest, nach
welcher der Eingabedialog abgebrochen werden soll, wenn keine Taste gedrückt wurde. Damit
können Eingaben automatisch abgebrochen werden, wenn der Nutzer nicht reagiert. Dieser Timeout
wird mit dem ersten Drücken einer Taste unterbrochen, da dann ja ein Nutzer da ist. Das heißt
nach dem ersten Drücken einer Taste wird die Eingabe nicht mehr angebrochen, wenn innerhalb der
Timeout-Zeit keine weitere Taste gedrückt wurde. Ein Wert von 0 für diesen Parameter deaktiviert
den Timeout gänzlich. Defaultwert ist 0.

Mask:
Dieser Parameter kann 0 oder 1 sein. Bei 1 werden in numerischen Eingabefeldern nicht die
eingegebenen Zahlen angezeigt, sondern das Zeichen "*". Das kann für die verdeckte Eingabe
von PIN-Nummern verwendet werden. Defaultwert ist 0.

BreakOnHelp
Dieser Parameter kann 0 oder 1 sein. Bei 1 wird in Anlehnung an des LCD-Menü bei Drücken der
"?"-Taste die Eingabe abgebrochen und statt des Ergebnisstrings das Zeichen "?" zurückgeliefert.
Das kann z.B. bei der PIN-Eingabe vom Script als Aufforderung ausgewertet werden, daß der User
die PIN ändern möchte. Defaultwert ist 0.

Rückgabewert:
input gibt die editierten Felder wieder ohne Füllzeichen über die Kommandozeile zurück. Dieser
Datenstring kann dann vom Script ausgewertet werden. Dabei ist zu beachten, daß die Kommandozeile
mehrfache Leerzeichen zusammenfasst. Also würde ein Text "X X" als "X X" beim Script ankom-
men. Das ist leider kommandozeilenbedingt und nicht zu verhindern.

Bedienung
----------------------------------
Mittels der Links-/Rechts-Tasten kann zwischen den einzelnen Eingabefeldern gewechselt werden.
Bei mehrzeiligen Eingabemasken kann mittels der Hoch-/Runter-Tasten auch zwischen den Zeilen
gewechselt werden.
Bei numerischen Eingabefeldern wird die Ziffer bei Druck auf eine Zifferntaste übernommen und
sofort zum nächsten Eingabefeld gewechselt. Bei alphanumerischen Feldern kann wie beim Handy
durch mehrfachen Druck der selben Taste durch die möglichen Buchstaben, Ziffern und Sonderzei-
chen geblättert werden. Der Druck auf eine andere als die bisher gedrückte Taste wird sofort
zum nächsten Feld gewechselt und der neue Wert dort übernommen. Wird in einem alphanumerischen
Feld nach Drücken einer Taste für 3 Sekunden keine weitere Taste betätigt, geht der Editor au-
tomatisch zum nächsten Eingabefeld. Damit ist die Eingabe zweier gleicher Buchstaben hinterein-
ander möglich, ohne erst die Cursortasten benutzen zu müssen.
Die rote Taste schaltet in alphanumerischen Eingabefeldern zwischen Groß- und Kleinschreibung
um. Die gelbe Taste löscht alle Eingabefelder.
Mit der Volume-Plus-Taste wird an der aktuellen Kursorposition ein Zeichen eingefügt. Der Rest
des Eingabefeldes rückt nach rechts. Das letzte Zeichen des Feldes verschwindet.
Mit der Volume-Minus-Taste wird das Zeichen an der aktuellen Kursorposition gelöscht. Der Rest
des Eingabefeldes rückt nach links.
Um das Plugin kurz auszublenden und das Fernsehbild zu sehen, kann die Mute-Taste gedrückt werden.
Das Plugin blendet dann alle grafischen Anzeigen aus und wartet so lange, bis wieder die Mute-
Taste gedrückt wird um anschließend ganz normal fortzusetzen. In der Zwischenzeit werden alle
anderen Tastendrücke ignoriert.
Mit "OK" werden die Änderungen übernommen und der Editor geschlossen. Die "HOME"-Taste bricht
den Vorgang ab, beendet den Editor und liefert einen Leerstring an das Script zurück.
Wenn mit dem Parameter "h=1" erlaubt, wird die Bearbeitung bei Drücken der "?"-Taste abgebrochen
und statt des Ergebnisstrings ein "?" zurückgegeben.

Beispiele
----------------------------------
Das Bild "small.png" ist ein Screenshot des Aufrufes:

input l="####" t="PIN"

Der Editor würde bei Eingabe von "1234" auch "1234" über die Kommandozeile zurückliefern.
Um diesen Wert einer Variablen zuzuordnen ( in diesem Fall "$pin", sollte der Aufruf so aussehen:

pin=`input l="####" t="PIN"`

Nun kann $pin wie gewohnt ausgewertet werden. Aber darauf achten: Bricht der User mit der "HOME"-
Taste ab, ist $pin leer.

Das Bild "big.png" ergibt sich mit folgendem Aufruf:

input l='Date: ##.##.####Time: ##:##:##' t='Datum und Uhrzeit ~andern' d='27022005164523' c=16 k=1

Der Rückgabewert bei Drücken der "OK"-Taste würde so aussehen: "27022005164523"


Sonderzeichen über die Kommandozeile
------------------------------------
Da Linux keine Übergabe von Sonder- und Steuerzeichen über die Kommandozeile unterstützt, können
die wichtigsten Sonderzeichen über die Nutzung des Formatsteuerzeichens sowohl aus Scripten als
auch von der Kommandozeile dargestellt werden. Aktuell werden folgende Sonder- und Steuerzeichen
unterstützt:

~a ä
~o ö
~u ü
~A Ä
~O Ö
~U Ü
~z ß
~d ° (degree)

Diese Steuerzeichen werden sowohl beim Titel, dem Format als auch dem Defaultstring ausgewertet.
Auch der Rückgabestring enthält die Umlaute als Steuerzeichen. Damit ist im Script ein leichteres
Ersetzen der Umlaute bei der Auswertung möglich.


Wird "input" mit falschen oder völlig ohne Parameter aufgerufen, wird im Log eine Liste der
unterstützten Parameter ausgegeben.
