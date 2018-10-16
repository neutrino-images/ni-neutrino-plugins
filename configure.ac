AC_INIT([neutrino-mp-plugins], [0.0.1])
AM_INIT_AUTOMAKE

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES])

AC_GNU_SOURCE

TUXBOX_APPS
TUXBOX_APPS_DIRECTORY
TUXBOX_APPS_PKGCONFIG
TUXBOX_BOXTYPE

AC_PROG_CC
AC_PROG_CXX
PKG_PROG_PKG_CONFIG
## both disabled => libtool still defaults to static
##                  at least the libtool I tested with ;-)
## --enable-shared => build only shared
## --enable-shared --enable-static => build both
AC_DISABLE_STATIC
AC_SYS_LARGEFILE
AC_PROG_LIBTOOL

PKG_CHECK_MODULES(CURL,libcurl)
PKG_CHECK_MODULES(FREETYPE,freetype2)
PKG_CHECK_MODULES(PNG,libpng)

AC_OUTPUT([
Makefile
cooliTSclimax/Makefile
FritzCallMonitor/Makefile
FritzInfoMonitor/Makefile
getrc/Makefile
input/Makefile
logomask/Makefile
msgbox/Makefile
satfind/Makefile
shellexec/Makefile
tuxcal/Makefile
tuxcom/Makefile
tuxmail/Makefile
tuxmail/daemon/Makefile
tuxwetter/Makefile
vinfo/Makefile
])
