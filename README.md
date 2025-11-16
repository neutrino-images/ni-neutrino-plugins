# Neutrino Mediathek Plugin

Choose your preferred language:

- [English](doc/README.en.md)
- [Deutsch](doc/README.de.md)

## Installation

For packaging systems (e.g. Yocto/OE) or any build environment that
supports a classic `make install` step, invoke the provided Makefile:

```
make install DESTDIR=<pkgdir> PREFIX=/usr/share/tuxbox/neutrino
```

The installation step copies the Lua sources, configuration file, hint icon
and resource directory to both `plugins` and `luaplugins` targets below the
selected prefix so that classic Neutrino builds and LuaJIT-based setups locate
identical content.  Uninstallation can be performed with `make uninstall
DESTDIR=<pkgdir> PREFIX=...`. The Makefile contains no build logic and is
therefore safe to call from any external build system that expects the
conventional install/uninstall targets.

To avoid naming conflicts the Makefile honours `PROGRAM_PREFIX`,
`PROGRAM_SUFFIX` and `PROGRAM_TRANSFORM_NAME`, mirroring the Autotools
convention. They influence both the Lua entry point and the resource
directory names:

```
make install PROGRAM_PREFIX=foo- DESTDIR=<pkgdir>
make install PROGRAM_SUFFIX=-bar DESTDIR=<pkgdir>
make install PROGRAM_TRANSFORM_NAME='s/-mediathek/-alt/' DESTDIR=<pkgdir>
```

## System Requirements

- A Neutrino image built from the DX repo (or a compatible downstream build).
- LuaJIT on the target is strongly recommended; the plugin works with stock Lua 5.1 but large list rendering runs noticeably slower.
- A reachable Mediathek API endpoint (public default or self-hosted). Use the settings menu or the `NEUTRINO_MEDIATHEK_API` environment variable to point the plugin at a custom URL.
