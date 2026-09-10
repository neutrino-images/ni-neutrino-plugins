# Neutrino Lua plugin scripts

English: [README.md](README.md)

Lua-Plugins für Neutrino, eines je Verzeichnis unter `plugins/`.
Daneben `share/lua/5.2/n_gui.lua` und `n_helpers.lua`, Helfer, die als
eigenes Paket ausgeliefert werden, und `xupnpd/`, Inhaltsdateien für den
xupnpd-Medienserver. Die Image-Rezepte holen bei jedem Build mit
Netzzugriff die Spitze von `master` von hier — was hier gepusht ist,
ist im nächsten Build.

Unter `plugins/` liegen zwei Sorten Plugin nebeneinander. Die meisten
sind Verzeichnisse mit ihren Dateien in diesem Repository. Vier sind
Git-Submodule mit eigenem Repository: `logoupdater`,
`neutrino-mediathek`, `stb_startup` und `webmin-setup`. Ein
Submodul-Eintrag ist ein *Pin*, der Commit, auf den er zeigt; Git nennt
den Eintrag *Gitlink*. Ziel ist ein Repository je Plugin; die
Verzeichnisse sind der noch nicht herausgelöste Teil.

**In einem Satz:** ein Plugin, das hier liegt, wird hier gefixt und
gepusht; ein Submodul-Plugin wird in seinem eigenen Repository gefixt,
und der Pin hier zieht von allein nach, das Superprojekt `plugins`
danach.

## Inhalt

1. [Klonen](#klonen)
2. [Ein Plugin ändern, das hier liegt](#ein-plugin-ändern-das-hier-liegt)
3. [Ein Submodul-Plugin ändern](#ein-submodul-plugin-ändern)
4. [Was von allein passiert](#was-von-allein-passiert)
5. [Commit-Subjects](#commit-subjects)
6. [Ein Plugin herauslösen](#ein-plugin-herauslösen)

## Klonen

Mit den Submodulen, sonst sind die vier leere Verzeichnisse:

```bash
git clone --recursive https://github.com/tuxbox-neutrino/plugin-scripts-lua.git
cd plugin-scripts-lua
git submodule status                # keine Zeile, die mit "-" beginnt
```

## Ein Plugin ändern, das hier liegt

Alles unter `plugins/<name>/`, das kein Submodul ist. Die Änderung vor
dem Push auf einer Box testen; der nächste Image-Build liefert sie aus.

```bash
cd plugins/<name>                   # z. B. plugins/webtv
$EDITOR <datei>
git add . && git commit -m "fix (<name>): ..."
git push
git log -1 origin/master            # dein Commit an der Spitze
```

## Ein Submodul-Plugin ändern

`plugins/logoupdater`, `plugins/neutrino-mediathek`,
`plugins/stb_startup`, `plugins/webmin-setup`. Du arbeitest im eigenen
Repository des Plugins, das ist der Checkout unter diesem Pfad. Ein
frischer Klon lässt ihn losgelöst auf dem Pin stehen, also zuerst auf
seinen Branch wechseln — `master` bei allen vieren:

```bash
cd plugins/<name>
git switch master && git pull
$EDITOR <datei>
git add . && git commit -m "fix (<name>): ..."
git push
git log -1 origin/master            # im Plugin-Repository
```

Der Pin hier zieht von allein nach (nächster Abschnitt). Soll er sofort
folgen, zurück in diesem Repository:

```bash
cd ../..                            # die Wurzel von plugin-scripts-lua
git submodule update --remote plugins/<name>   # holt den master des Plugins
git diff --submodule=log            # worüber der Pin springt: der Text fürs Subject
git add plugins/<name>
git commit -m "chore (plugins): <name>: <was sich bewegt hat>"
git push
```

## Was von allein passiert

Der Workflow `update-submodule-pins.yml` läuft jede Stunde (geplant zu
:17; GitHub startet ihn oft ein paar Minuten später), setzt jeden der
vier Pins auf die Spitze des Plugin-Branches und pusht das Ergebnis als
`GitHub Actions <actions@github.com>`. Auf einen Push reagiert nichts.
Das Superprojekt `plugins`, das dieses Repository als `scripts-lua`
einbindet, macht dasselbe um :47, sodass ein Plugin-Fix beide Ebenen
durchläuft, ohne auf eine zweite volle Runde zu warten.

Sofort statt warten: Actions → *Update submodule pins* → *Run workflow*,
oder mit der GitHub-CLI (`gh`). Der Lauf committet und pusht einen
Pin-Bump auf `master`, denselben, den der Timer später machen würde:

```bash
gh workflow run update-submodule-pins.yml -R tuxbox-neutrino/plugin-scripts-lua --ref master
gh run list -R tuxbox-neutrino/plugin-scripts-lua -L 1   # der Lauf und sein Ergebnis
```

Wie der Pin-Commit formuliert ist, welchem Branch ein Pin folgt und was
zu tun ist, wenn der Workflow ausfällt, steht im README des
Superprojekts unter
[Was von allein passiert](https://github.com/tuxbox-neutrino/plugins/blob/master/README.de.md#was-von-allein-passiert).
Beachte: Commit-Subjects haben dort eine andere Form als hier.

## Commit-Subjects

Ab jetzt `<type> (<scope>): <summary>`, höchstens 72 Spalten, der Scope
ist das Plugin-Verzeichnis oder das geänderte Skript darin:

```
fix (yt_live): escape the ampersands in the channel list
chore (plugins): drop the stale stb_startup copy
```

Ältere Commits folgen dem noch nicht; neue tun es.

## Ein Plugin herauslösen

Ziel ist ein Repository je Plugin, benannt `plugin-lua-<name>` mit
Unterstrichen als Bindestriche (`stb_startup` →
`plugin-lua-stb-startup`; `neutrino-mediathek` ist die historische
Ausnahme). Das Repository unter `tuxbox-neutrino/` anlegen, die Dateien
mit ihrer Historie dorthin bringen, dann hier das Verzeichnis durch den
Pin ersetzen:

```bash
git rm -r plugins/<name>
git submodule add ../plugin-lua-<name>.git plugins/<name>
git commit -m "build (plugins): link <name> as a submodule"
git ls-tree HEAD plugins/<name>     # "160000 commit ...": jetzt ein Gitlink
```

Im selben Zug das Rezept des Plugins in `meta-neutrino` auf das neue
Repository zeigen lassen: die Rezepte extrahieren `plugins/<name>` aus
diesem Repository, und hinter einem Gitlink findet diese Extraktion
nichts. Rezeptnamen weichen von Verzeichnisnamen ab; das Rezept findest
du über seinen Quellnamen (ein Rezept ohne `SRC_NAME` nutzt seinen
eigenen Namen):

```bash
grep -rl 'SRC_NAME = "<name>"' meta-neutrino/recipes-neutrino/neutrino-plugins-lua/
```
