# Neutrino Mediathek Plugin

Choose your preferred language:

- [English](doc/README.en.md)
- [Deutsch](doc/README.de.md)

## Installation

For packaging systems (e.g. Yocto/OE) invoke the provided Makefile:

```
make install DESTDIR=<pkgdir> PREFIX=/usr/share/tuxbox/neutrino
```

The installation step copies the Lua sources, configuration file, hint icon
and resource directory to both `plugins` and `luaplugins` targets below the
selected prefix so that classic Neutrino builds and LuaJIT-based setups locate
identical content.  Uninstallation can be performed with `make uninstall
DESTDIR=<pkgdir> PREFIX=...`.
