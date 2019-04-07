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
emmrd/Makefile
FritzCallMonitor/Makefile
FritzInfoMonitor/Makefile
getrc/Makefile
input/Makefile
logomask/Makefile
msgbox/Makefile
oscammon/Makefile
satfind/Makefile
scripts-lua/plugins/add-locale/Makefile
scripts-lua/plugins/ard_mediathek/Makefile
scripts-lua/plugins/epgfilter/Makefile
scripts-lua/plugins/EPGscan/Makefile
scripts-lua/plugins/favorites2bin/Makefile
scripts-lua/plugins/heizoelpreise/Makefile
scripts-lua/plugins/LocalTV/Makefile
scripts-lua/plugins/logoupdater/Makefile
scripts-lua/plugins/mtv/Makefile
scripts-lua/plugins/netzkino/Makefile
scripts-lua/plugins/openvpn-setup/Makefile
scripts-lua/plugins/openvpn-setup/openvpn-setup/Makefile
scripts-lua/plugins/stb_startup/Makefile
scripts-lua/plugins/userbouquets/Makefile
scripts-sh/plugins/autoreboot/Makefile
scripts-sh/plugins/dropbox_uploader/Makefile
scripts-sh/plugins/imgbackup-hd51/Makefile
scripts-sh/plugins/mountpointmanagement/Makefile
scripts-sh/plugins/pr-auto-timer/Makefile
scripts-sh/plugins/smarthomeinfo/Makefile
shellexec/Makefile
showiframe/Makefile
stbup/Makefile
tuxcal/daemon/Makefile
tuxcal/Makefile
tuxcom/Makefile
tuxmail/daemon/Makefile
tuxmail/Makefile
tuxwetter/Makefile
vinfo/Makefile
])
