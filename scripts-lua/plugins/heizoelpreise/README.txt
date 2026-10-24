Heizölpreise 1.0.1 – NI-Neutrino
================================

Zeigt aktuelle Heizöl-Durchschnittspreise für Deutschland und Österreich
sowie die Preise der Bundesländer (Quelle: HeizOel24).

Installation:
  heizoelpreise.lua und heizoelpreise.cfg nach
  /usr/share/tuxbox/neutrino/plugins/ kopieren.
  Anschließend das Plugin über das Neutrino-Pluginmenü starten.

Bedienung:
  Hauptansicht: ROT = Land wechseln; BLAU = Bundesländer;
                GRÜN oder HOME/EXIT = Plugin beenden.
  Bundesländer: BLAU oder HOME/EXIT = zurück zur Hauptansicht;
                bei mehrseitiger Anzeige mit LINKS/RECHTS blättern.

Hinweise:
  Benötigt curl, funktionierende HTTPS-Zertifikatsprüfung und
  eine korrekt eingestellte Systemzeit.
  Auf alten Receivern kann das Laden länger dauern.

Änderungen in 1.0.1:
  - OSD-Anpassungen für 1280x720 und 1920x1080
  - Kompakte Bundesländeransicht mit Seitenwechsel
  - Korrigierte Footer-Abstände
  - Sauberes Beenden per HOME/EXIT

Release-Basis: erfolgreich getestete 1.0.1 RC4.
