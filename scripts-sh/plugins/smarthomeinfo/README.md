# NI-FRITZ!Smart Home Info#

## von fred_feuerstein (NI-Team)

LoginTeil zur Ermittlung der FritzBox SID nach Vorlage von "http :// www .wehavemorefun.de/fritzbox/Anruf-liste_von_der_Box_holen"

Das Plugin/Skript schaltet Fritz!Dect200/210
Steckdosen, sowie Powerline 546E von AVM,
und Comet Dect Heizungsthermostate, bzw.
die baugleichen Fritz!Dect 300/301 Thermostate
die mit der FritzBox gekoppelt sind im toggle-Mode ein/aus und zeigt
alle Statusinfos zur Steckdose
         
### Vorbereitung: ###
die Login-Daten fuer die FritzBox werden aus
der smarthomeinfo.conf geholt. Bitte die
Datei unter (var/tuxbox/config) vorher anpassen
Wenn der Login bei der Fritzbox nur aus Passwort besteht (meistens), 
dann wird das Feld USERNM in der conf leer lassen.

### Installation ###
smarthomeinfo.conf kommt nach /var/tuxbox/config

smarthomeinfo.so kommt nach /usr/share/tuxbox/neutrino/plugins (Rechte auf 755)
smarthomeinfo.cfg kommt nach /usr/share/tuxbox/neutrino/plugins
smarthomeinfo_hint.png kommt nach /usr/share/tuxbox/neutrino/plugins

Falls das Plugin nicht unter /usr/share/tuxbox/neutrino/plugins, sondern bspw. unter /var/tuxbox/plugins installiert wird, dann muss das in der conf Datei entsprechend angepasst werden.

