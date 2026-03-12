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
make install DESTDIR=$PWD/dist PREFIX=/usr
```

This installs files to:
`dist/usr/share/neutrino/plugins/lua/stb_startup`
