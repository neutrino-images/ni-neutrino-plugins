# plugin-lua-stb-startup

Standalone Neutrino Lua plugin for multiboot startup switching.

## What This Plugin Does

- Detects available startup entries and the currently active slot.
- Lets users select the startup slot for the next reboot.
- Supports boxmode switching (1/12) where supported by the platform layout.
- Shows slot details (for example startup entry and root partition).

## Repository Layout

- `plugin/stb-startup.lua`
- `plugin/stb-startup.cfg`
- `plugin/stb-startup.conf`
- `plugin/stb-startup_hint.png`
- `metadata.json`
- `LICENSE`

## Runtime Requirements

- Neutrino Lua runtime with `filehelpers` and `configfile` APIs.
- Standard target tools: `mount`, `umount`, `sleep`.
- Writable Neutrino config directory.

Config resolution in plugin runtime:

- Preferred: `/var/tuxbox/config`
- Fallback: `/etc/neutrino/config`

The plugin stores its settings in `stb-startup.conf`. In OE packaging, this file is
typically symlinked from the plugin directory to `/etc/neutrino/config/stb-startup.conf`
for persistent system-wide storage.

## Build And Install

Default install (real root or staging via `DESTDIR`):

```bash
make install
```

Package/staging install example:

```bash
make install DESTDIR=/tmp/pkgroot PREFIX=/usr/share/tuxbox/neutrino PLUGIN_SUBDIR=plugins
```

Quick local test tree:

```bash
make install-local
```

OpenEmbedded recipe-style install:

```bash
oe_runmake \
  DESTDIR=${D} \
  PREFIX=${N_PREFIX}${N_DATADIR}/neutrino \
  PLUGIN_SUBDIR=$(basename ${N_PLUGIN_DIR}) \
  install
```

## Cleanup

```bash
make uninstall DESTDIR=/tmp/pkgroot PREFIX=/usr/share/tuxbox/neutrino PLUGIN_SUBDIR=plugins
make clean
```

## License

BSD-2-Clause
