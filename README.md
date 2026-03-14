# plugin-lua-stb-startup

Standalone Neutrino Lua plugin for multiboot startup switching (`stb-startup`).

## Contents

- `plugin/stb-startup.lua`
- `plugin/stb-startup.cfg`
- `plugin/stb-startup.conf`
- `plugin/stb-startup_hint.png`
- `LICENSE`

## Version

Current plugin baseline: `v2.0`

## Install (local)

```bash
make install DESTDIR=/tmp/pkgroot PREFIX=/usr/share/tuxbox/neutrino PLUGIN_SUBDIR=plugins
```

This installs files to:
`/tmp/pkgroot/usr/share/tuxbox/neutrino/plugins`

For a quick local test tree:

```bash
make install-local
```
