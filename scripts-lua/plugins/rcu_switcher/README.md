# RCU-Switcher / Fernbedienungsauswahl
damit kann definiert werden welche Fernbedienung man verwenden möchte. Die Bestätigung erfolgt mit
der Ausgewählten Fernbedienung. Damit nach Neustart die Auswahl beibehalten wird, muss eine Erweiterung
in eine der Startdateien erfolgen.

z.b. wie folgt in der rcS, rcS.local, start_neutrino  oder monolithisch in der init.d (S99_rcu oder ähnlich)
```
RCCODE="/etc/rccode"
[ -e /var/etc/rccode ] && RCCODE="/var/etc/rccode"

if [ -e $RCCODE ] && [ $(cat $RCCODE) != $(cat /proc/stb/ir/rc/type) ]; then
    echo "Switching remote protocol"
	case $(cat $RCCODE) in
		4) echo 4 > /proc/stb/ir/rc/type;;
		5) echo 5 > /proc/stb/ir/rc/type;;
		7) echo 7 > /proc/stb/ir/rc/type;;
		8) echo 8 > /proc/stb/ir/rc/type;;
		9) echo 9 > /proc/stb/ir/rc/type;;
		11) echo 11 > /proc/stb/ir/rc/type;;
		13) echo 13 > /proc/stb/ir/rc/type;;
		16) echo 16 > /proc/stb/ir/rc/type;;
		21) echo 21 > /proc/stb/ir/rc/type;;
		23) echo 23 > /proc/stb/ir/rc/type;;
		* ) echo "[rcu_switcher] unknown rc code";;
	esac
fi
```
