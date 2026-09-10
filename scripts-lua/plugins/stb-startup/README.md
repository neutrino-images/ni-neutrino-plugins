# plugin-lua-stb-startup

Standalone Neutrino Lua plugin for multiboot startup switching.

## What This Plugin Does

- Detects available startup entries and the currently active slot.
- Lets users select the startup slot for the next reboot.
- Supports boxmode switching (1/12) where supported by the platform layout.
- Shows slot details (for example startup entry and root partition).
- Self-heals stale udev coldplug state and falls back to `blkid` when
  `/dev/disk/by-partlabel/` is empty (see "Robustness — v2.4" below).
- Auto-backs up `/boot/STARTUP` to `/boot/STARTUP.bak` before every switch.

## Robustness — v2.4

Layout detection works in three layers; the plugin walks down the list
until one yields a working PARTLABEL → device map:

1. `/dev/disk/by-partlabel/` (populated by `udev` after the coldplug
   `IMPORT{builtin}="blkid"` pass).
2. **Self-repair**: if the directory is empty, the plugin runs
   `udevadm trigger --subsystem-match=block --action=change` followed by
   `udevadm settle --timeout=3`. This works around images where
   `systemd-udev-trigger.service` is not wired into `sysinit.target.wants/`.
3. **`blkid -o export` fallback**: if even the trigger does not populate
   `by-partlabel`, the plugin parses `blkid -o export` to build a
   `PARTLABEL → DEVNAME` map directly from probe results. Busybox `blkid`
   is sufficient — no additional package dependency.

The slot-list UI shows a small `udev:` status indicator if the coldplug
was repaired or missing, so the layer that fixed the lookup is visible
without journal access. If the boot partition cannot be mounted because
labels are completely missing, the user sees a precise diagnostic message
("Partition labels not detected — udev coldplug missing in image, image
update needed") instead of a generic mount-failure error.

`/boot/STARTUP` is automatically copied to `/boot/STARTUP.bak` before any
slot switch. If a switch causes a bad reboot, recovery is a single
`cp /boot/STARTUP.bak /boot/STARTUP`.

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
