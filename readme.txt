Was ist getrc?
----------------------------------
getrc ermöglicht die Abfrage der Fernbedienung nun auch für Scripte. Mit vorgebbarem
Timeout und optionaler Zieltaste kann nun auch aus Scripten flexibel auf Fernbedie-
numgsaktionen reagiert werden.

Installation
----------------------------------
Die Datei getrc kommt mit den Rechten 755 nach /var/bin/. Das ist alles.

Anwendung
----------------------------------
Der Aufruf von getrc kann aus einem Script heraus erfolgen. getrc gibt nun entweder
den Code der gedrückten Taste über die Konsole zurück oder ein "X", wenn ein Timeout
aufgetreten ist. Den Tasten sind dabei folgende Codes zugeordnet:

  Taste
  	0          0
 	1          1
 	2          2
 	3          3
 	4          4
 	5          5
 	6          6
 	7          7
 	8          8
 	9          9
 	RECHTS     A
 	LINKS      B
 	HOCH       C
 	RUNTER     D
 	OK         E
 	MUTE       F
 	STANDBY    G
 	GRUEN      H
 	GELB       I
 	ROT        J
 	BLAU       K
 	VOL_PLUS   L
 	VOL_MINUS  M
 	HELP       N
 	MENU       O
 	EXIT       P
 
 extra Tasten der Coolstream
 	
 	PAGEUP     Q
 	PAGEDOWN   R
 	TV/R       S
 	TTX        T
 	COOL       U
 	FAV        V
 	EPG        W
 	V.F        Y
 	SAT        Z
 	SKIP+      a
 	SKIP-      b
 	T/S        c
 	AUDIO      d
 	REW        e
 	FWD        f
 	PAUSE      g
 	REC        h
 	STOP       i
 	PLAY       j

Die Aufrufzeile sieht so aus:

  getrc key=X timeout=ms
  
mit X=Tastencode und ms=Timeoutzeit in Millisekunden. Der Aufruf "getrc key=E timeout=5000"
würde also höchstens 5 Sekunden lang auf das Drücken der OK warten. Wird innerhalb dieser
Zeit die OK-Taste gedrückt, kehrt getrc mit der Konsolenausgabe "E" zurück. Anderenfalls
würde es nach 5 Sekunden "X" auf der Konsole ausgeben und sich beenden. Die Parameter "key="
und "timeout=" sind optional und können einzeln oder auch beide weggelassen werden. Ein
Aufruf "getrc key=P" würde also unbegrenzt lange auf das Drücken der HOME-Taste warten,
der Aufruf "getrc timeout=5000" 5 Sekunden lang auf einen beliebigen Tastendruck und "getrc"
schließlich unbegrenzt lange auf einen beliebigen Tastendruck.
Um die Konsolenausgabe von getrc im Script beispielsweise der Variable "key" zuzuweisen,
muß der Aufruf so erfolgen:

	key=`getrc`
	
wahlweise natürlich auch wieder mit den Kommandozeilenparametern.
