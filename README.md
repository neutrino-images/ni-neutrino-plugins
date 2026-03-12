# plugin-lua-stb-startup

Standalone Neutrino Lua plugin for multiboot startup switching (`stb-startup`).

## Contents

- `stb_startup/stb-startup.lua`
- `stb_startup/stb-startup.cfg`
- `stb_startup/stb-startup.conf`
- `stb_startup/stb-startup_hint.png`
- `LICENSE`

## Version

Current plugin baseline: `v2.0`

## Install (local)

```bash
make install DESTDIR=$PWD/dist PREFIX=/usr
```

This installs files to:
`dist/usr/share/neutrino/plugins/lua/stb_startup`
