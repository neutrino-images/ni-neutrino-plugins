# NI \o/ - Neutrino-Plugins

Tuxbox-Plugins were added with

```
#!bash
for plugin in cooliTSclimax getrc input logomask logoview msgbox scripts-lua shellexec sysinfo tuxcal tuxcom tuxmail tuxwetter; do
	git subtree add --prefix=$plugin https://github.com/tuxbox-neutrino/plugin-$plugin.git master
done
```
