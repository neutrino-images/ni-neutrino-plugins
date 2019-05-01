AC_INIT([neutrino-mp-plugins],[0.0.1])
AM_INIT_AUTOMAKE([foreign])
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
LT_INIT

PKG_CHECK_MODULES(CURL,libcurl)
PKG_CHECK_MODULES(FREETYPE,freetype2)
PKG_CHECK_MODULES(PNG,libpng)

AC_ARG_WITH(neutrino-source,
	AS_HELP_STRING([--with-neutrino-source=PATH], [path where Neutrino source is located @<:@default=NONE@:>@]]),
	[NEUTRINO_SOURCE="$withval"],
	[NEUTRINO_SOURCE=""])
AC_SUBST(NEUTRINO_SOURCE)

AC_ARG_WITH(neutrino-build,
	AS_HELP_STRING([--with-neutrino-build=PATH], [path where Neutrino is built @<:@default=NONE@:>@]]),
	[NEUTRINO_BUILD="$withval"],
	[NEUTRINO_BUILD=""])
AC_SUBST(NEUTRINO_BUILD)

AC_ARG_ENABLE(coolitsclimax,
	AS_HELP_STRING([--enable-coolitsclimax], [enable coolitsclimax @<:@default=yes@:>@]),
	[enable_coolitsclimax="$enableval"],
	[enable_coolitsclimax="yes"])
AM_CONDITIONAL(ENABLE_COOLITSCLIMAX, test "$enable_coolitsclimax" = "yes")

AC_ARG_ENABLE(emmrd,
	AS_HELP_STRING([--enable-emmrd], [enable emmrd @<:@default=yes@:>@]),
	[enable_emmrd="$enableval"],
	[enable_emmrd="yes"])
AM_CONDITIONAL(ENABLE_EMMRD, test "$enable_emmrd" = "yes")

AC_ARG_ENABLE(fritzcallmonitor,
	AS_HELP_STRING([--enable-fritzcallmonitor], [enable fritzcallmonitor @<:@default=yes@:>@]),
	[enable_fritzcallmonitor="$enableval"],
	[enable_fritzcallmonitor="yes"])
AM_CONDITIONAL(ENABLE_FRITZCALLMONITOR, test "$enable_fritzcallmonitor" = "yes")

AC_ARG_ENABLE(fritzinfomonitor,
	AS_HELP_STRING([--enable-fritzinfomonitor], [enable fritzinfomonitor @<:@default=yes@:>@]),
	[enable_fritzinfomonitor="$enableval"],
	[enable_fritzinfomonitor="yes"])
AM_CONDITIONAL(ENABLE_FRITZINFOMONITOR, test "$enable_fritzinfomonitor" = "yes")

AC_ARG_ENABLE(getrc,
	AS_HELP_STRING([--enable-getrc], [enable getrc @<:@default=yes@:>@]),
	[enable_getrc="$enableval"],
	[enable_getrc="yes"])
AM_CONDITIONAL(ENABLE_GETRC, test "$enable_getrc" = "yes")

AC_ARG_ENABLE(input,
	AS_HELP_STRING([--enable-input], [enable input @<:@default=yes@:>@]),
	[enable_input="$enableval"],
	[enable_input="yes"])
AM_CONDITIONAL(ENABLE_INPUT, test "$enable_input" = "yes")

AC_ARG_ENABLE(logomask,
	AS_HELP_STRING([--enable-logomask], [enable logomask @<:@default=yes@:>@]),
	[enable_logomask="$enableval"],
	[enable_logomask="yes"])
AM_CONDITIONAL(ENABLE_LOGOMASK, test "$enable_logomask" = "yes")

AC_ARG_ENABLE(logoview,
	AS_HELP_STRING([--enable-logoview], [enable logoview @<:@default=yes@:>@]),
	[enable_logoview="$enableval"],
	[enable_logoview="yes"])
AM_CONDITIONAL(ENABLE_LOGOVIEW, test "$enable_logoview" = "yes")

AS_IF(test "$enable_logoview" = "yes",
	AS_IF(test -z "$NEUTRINO_SOURCE", AC_MSG_ERROR([logoview needs --with-neutrino-source=...]))
	AS_IF(test -z "$NEUTRINO_BUILD",  AC_MSG_ERROR([logoview needs --with-neutrino-build=...])))

AC_ARG_ENABLE(msgbox,
	AS_HELP_STRING([--enable-msgbox], [enable msgbox @<:@default=yes@:>@]),
	[enable_msgbox="$enableval"],
	[enable_msgbox="yes"])
AM_CONDITIONAL(ENABLE_MSGBOX, test "$enable_msgbox" = "yes")

AC_ARG_ENABLE(oscammon,
	AS_HELP_STRING([--enable-oscammon], [enable oscammon @<:@default=yes@:>@]),
	[enable_oscammon="$enableval"],
	[enable_oscammon="yes"])
AM_CONDITIONAL(ENABLE_OSCAMMON, test "$enable_oscammon" = "yes")

AC_ARG_ENABLE(satfind,
	AS_HELP_STRING([--enable-satfind], [enable satfind @<:@default=yes@:>@]),
	[enable_satfind="$enableval"],
	[enable_satfind="yes"])
AM_CONDITIONAL(ENABLE_SATFIND, test "$enable_satfind" = "yes")

AC_ARG_ENABLE(shellexec,
	AS_HELP_STRING([--enable-shellexec], [enable shellexec @<:@default=yes@:>@]),
	[enable_shellexec="$enableval"],
	[enable_shellexec="yes"])
AM_CONDITIONAL(ENABLE_SHELLEXEC, test "$enable_shellexec" = "yes")

AC_ARG_ENABLE(showiframe,
	AS_HELP_STRING([--enable-showiframe], [enable showiframe @<:@default=yes@:>@]),
	[enable_showiframe="$enableval"],
	[enable_showiframe="yes"])
AM_CONDITIONAL(ENABLE_SHOWIFRAME, test "$enable_showiframe" = "yes")

AC_ARG_ENABLE(stbup,
	AS_HELP_STRING([--enable-stbup], [enable stbup @<:@default=yes@:>@]),
	[enable_stbup="$enableval"],
	[enable_stbup="yes"])
AM_CONDITIONAL(ENABLE_STBUP, test "$enable_stbup" = "yes")

AC_ARG_ENABLE(tuxcal,
	AS_HELP_STRING([--enable-tuxcal], [enable tuxcal @<:@default=yes@:>@]),
	[enable_tuxcal="$enableval"],
	[enable_tuxcal="yes"])
AM_CONDITIONAL(ENABLE_TUXCAL, test "$enable_tuxcal" = "yes")

AC_ARG_ENABLE(tuxcom,
	AS_HELP_STRING([--enable-tuxcom], [enable tuxcom @<:@default=yes@:>@]),
	[enable_tuxcom="$enableval"],
	[enable_tuxcom="yes"])
AM_CONDITIONAL(ENABLE_TUXCOM, test "$enable_tuxcom" = "yes")

AC_ARG_ENABLE(tuxmail,
	AS_HELP_STRING([--enable-tuxmail], [enable tuxmail @<:@default=yes@:>@]),
	[enable_tuxmail="$enableval"],
	[enable_tuxmail="yes"])
AM_CONDITIONAL(ENABLE_TUXMAIL, test "$enable_tuxmail" = "yes")

AC_ARG_ENABLE(tuxwetter,
	AS_HELP_STRING([--enable-tuxwetter], [enable tuxwetter @<:@default=yes@:>@]),
	[enable_tuxwetter="$enableval"],
	[enable_tuxwetter="yes"])
AM_CONDITIONAL(ENABLE_TUXWETTER, test "$enable_tuxwetter" = "yes")

AC_ARG_ENABLE(vinfo,
	AS_HELP_STRING([--enable-vinfo], [enable vinfo @<:@default=yes@:>@]),
	[enable_vinfo="$enableval"],
	[enable_vinfo="yes"])
AM_CONDITIONAL(ENABLE_VINFO, test "$enable_vinfo" = "yes")

AC_ARG_ENABLE(add-locale,
	AS_HELP_STRING([--enable-add-locale], [enable add-locale @<:@default=yes@:>@]),
	[enable_add_locale="$enableval"],
	[enable_add_locale="yes"])
AM_CONDITIONAL(ENABLE_ADD_LOCALE, test "$enable_add_locale" = "yes")

AC_ARG_ENABLE(ard_mediathek,
	AS_HELP_STRING([--enable-ard_mediathek], [enable ard_mediathek @<:@default=yes@:>@]),
	[enable_ard_mediathek="$enableval"],
	[enable_ard_mediathek="yes"])
AM_CONDITIONAL(ENABLE_ARD_MEDIATHEK, test "$enable_ard_mediathek" = "yes")

AC_ARG_ENABLE(epgfilter,
	AS_HELP_STRING([--enable-epgfilter], [enable epgfilter @<:@default=yes@:>@]),
	[enable_epgfilter="$enableval"],
	[enable_epgfilter="yes"])
AM_CONDITIONAL(ENABLE_EPGFILTER, test "$enable_epgfilter" = "yes")

AC_ARG_ENABLE(epgscan-setup,
	AS_HELP_STRING([--enable-epgscan-setup], [enable epgscan-setup @<:@default=yes@:>@]),
	[enable_epgscan_setup="$enableval"],
	[enable_epgscan_setup="yes"])
AM_CONDITIONAL(ENABLE_EPGSCAN_SETUP, test "$enable_epgscan_setup" = "yes")

AC_ARG_ENABLE(favorites2bin,
	AS_HELP_STRING([--enable-favorites2bin], [enable favorites2bin @<:@default=yes@:>@]),
	[enable_favorites2bin="$enableval"],
	[enable_favorites2bin="yes"])
AM_CONDITIONAL(ENABLE_FAVORITES2BIN, test "$enable_favorites2bin" = "yes")

AC_ARG_ENABLE(fritzinfomonitor-setup,
	AS_HELP_STRING([--enable-fritzinfomonitor-setup], [enable fritzinfomonitor-setup @<:@default=yes@:>@]),
	[enable_fritzinfomonitor_setup="$enableval"],
	[enable_fritzinfomonitor_setup="yes"])
AM_CONDITIONAL(ENABLE_FRITZINFOMONITOR_SETUP, test "$enable_fritzinfomonitor_setup" = "yes")

AC_ARG_ENABLE(heizoelpreise,
	AS_HELP_STRING([--enable-heizoelpreise], [enable heizoelpreise @<:@default=yes@:>@]),
	[enable_heizoelpreise="$enableval"],
	[enable_heizoelpreise="yes"])
AM_CONDITIONAL(ENABLE_HEIZOELPREISE, test "$enable_heizoelpreise" = "yes")

AC_ARG_ENABLE(localtv,
	AS_HELP_STRING([--enable-localtv], [enable localtv @<:@default=yes@:>@]),
	[enable_localtv="$enableval"],
	[enable_localtv="yes"])
AM_CONDITIONAL(ENABLE_LOCALTV, test "$enable_localtv" = "yes")

AC_ARG_ENABLE(logoupdater,
	AS_HELP_STRING([--enable-logoupdater], [enable logoupdater @<:@default=yes@:>@]),
	[enable_logoupdater="$enableval"],
	[enable_logoupdater="yes"])
AM_CONDITIONAL(ENABLE_LOGOUPDATER, test "$enable_logoupdater" = "yes")

AC_ARG_ENABLE(mtv,
	AS_HELP_STRING([--enable-mtv], [enable mtv @<:@default=yes@:>@]),
	[enable_mtv="$enableval"],
	[enable_mtv="yes"])
AM_CONDITIONAL(ENABLE_MTV, test "$enable_mtv" = "yes")

AC_ARG_ENABLE(netzkino,
	AS_HELP_STRING([--enable-netzkino], [enable netzkino @<:@default=yes@:>@]),
	[enable_netzkino="$enableval"],
	[enable_netzkino="yes"])
AM_CONDITIONAL(ENABLE_NETZKINO, test "$enable_netzkino" = "yes")

AC_ARG_ENABLE(openvpn-setup,
	AS_HELP_STRING([--enable-openvpn-setup], [enable openvpn-setup @<:@default=yes@:>@]),
	[enable_openvpn_setup="$enableval"],
	[enable_openvpn_setup="yes"])
AM_CONDITIONAL(ENABLE_OPENVPN_SETUP, test "$enable_openvpn_setup" = "yes")

AC_ARG_ENABLE(stb_startup,
	AS_HELP_STRING([--enable-stb_startup], [enable stb_startup @<:@default=yes@:>@]),
	[enable_stb_startup="$enableval"],
	[enable_stb_startup="yes"])
AM_CONDITIONAL(ENABLE_STB_STARTUP, test "$enable_stb_startup" = "yes")

AC_ARG_ENABLE(userbouquets,
	AS_HELP_STRING([--enable-userbouquets], [enable userbouquets @<:@default=yes@:>@]),
	[enable_userbouquets="$enableval"],
	[enable_userbouquets="yes"])
AM_CONDITIONAL(ENABLE_USERBOUQUETS, test "$enable_userbouquets" = "yes")

AC_ARG_ENABLE(autoreboot,
	AS_HELP_STRING([--enable-autoreboot], [enable autoreboot @<:@default=yes@:>@]),
	[enable_autoreboot"$enableval"],
	[enable_autoreboot="yes"])
AM_CONDITIONAL(ENABLE_AUTOREBOOT, test "$enable_autoreboot" = "yes")

AC_ARG_ENABLE(dropbox_uploader,
	AS_HELP_STRING([--enable-dropbox_uploader], [enable dropbox_uploader @<:@default=yes@:>@]),
	[enable_dropbox_uploader="$enableval"],
	[enable_dropbox_uploader="yes"])
AM_CONDITIONAL(ENABLE_DROPBOX_UPLOADER, test "$enable_dropbox_uploader" = "yes")

AC_ARG_ENABLE(epgscan,
	AS_HELP_STRING([--enable-epgscan], [enable epgscan @<:@default=yes@:>@]),
	[enable_epgscan="$enableval"],
	[enable_epgscan="yes"])
AM_CONDITIONAL(ENABLE_EPGSCAN, test "$enable_epgscan" = "yes")

AC_ARG_ENABLE(imgbackup-hd51,
	AS_HELP_STRING([--enable-imgbackup-hd51], [enable imgbackup-hd51 @<:@default=yes@:>@]),
	[enable_imgbackup_hd51="$enableval"],
	[enable_imgbackup_hd51="yes"])
AM_CONDITIONAL(ENABLE_IMGBACKUP_HD51, test "$enable_imgbackup_hd51" = "yes")

AC_ARG_ENABLE(mountpointmanagement,
	AS_HELP_STRING([--enable-mountpointmanagement], [enable mountpointmanagement @<:@default=yes@:>@]),
	[enable_mountpointmanagement="$enableval"],
	[enable_mountpointmanagement="yes"])
AM_CONDITIONAL(ENABLE_MOUNTPOINTMANAGEMENT, test "$enable_mountpointmanagement" = "yes")

AC_ARG_ENABLE(pr-auto-timer,
	AS_HELP_STRING([--enable-pr-auto-timer], [enable pr-auto-timer @<:@default=yes@:>@]),
	[enable_pr_auto_timer="$enableval"],
	[enable_pr_auto_timer="yes"])
AM_CONDITIONAL(ENABLE_PR_AUTO_TIMER, test "$enable_pr_auto_timer" = "yes")

AC_ARG_ENABLE(smarthomeinfo,
	AS_HELP_STRING([--enable-smarthomeinfo], [enable smarthomeinfo @<:@default=yes@:>@]),
	[enable_smarthomeinfo="$enableval"],
	[enable_smarthomeinfo="yes"])
AM_CONDITIONAL(ENABLE_SMARTHOMEINFO, test "$enable_smarthomeinfo" = "yes")

AC_CONFIG_FILES([
Makefile
cooliTSclimax/Makefile
data/Makefile
data/fonts/Makefile
emmrd/Makefile
FritzCallMonitor/Makefile
FritzInfoMonitor/Makefile
getrc/Makefile
input/Makefile
logomask/Makefile
logoview/Makefile
msgbox/Makefile
oscammon/Makefile
satfind/Makefile
scripts-lua/Makefile
scripts-lua/plugins/Makefile
scripts-lua/plugins/add-locale/Makefile
scripts-lua/plugins/ard_mediathek/Makefile
scripts-lua/plugins/epgfilter/Makefile
scripts-lua/plugins/EPGscan-setup/Makefile
scripts-lua/plugins/favorites2bin/Makefile
scripts-lua/plugins/FritzInfoMonitor-setup/Makefile
scripts-lua/plugins/heizoelpreise/Makefile
scripts-lua/plugins/LocalTV/Makefile
scripts-lua/plugins/logoupdater/Makefile
scripts-lua/plugins/mtv/Makefile
scripts-lua/plugins/netzkino/Makefile
scripts-lua/plugins/openvpn-setup/Makefile
scripts-lua/plugins/openvpn-setup/openvpn-setup/Makefile
scripts-lua/plugins/stb_startup/Makefile
scripts-lua/plugins/userbouquets/Makefile
scripts-lua/plugins/webradio/Makefile
scripts-lua/plugins/webtv/Makefile
scripts-sh/Makefile
scripts-sh/plugins/Makefile
scripts-sh/plugins/autoreboot/Makefile
scripts-sh/plugins/dropbox_uploader/Makefile
scripts-sh/plugins/EPGscan/Makefile
scripts-sh/plugins/imgbackup-hd51/Makefile
scripts-sh/plugins/mountpointmanagement/Makefile
scripts-sh/plugins/pr-auto-timer/Makefile
scripts-sh/plugins/smarthomeinfo/Makefile
shellexec/Makefile
showiframe/Makefile
stbup/Makefile
tuxcal/Makefile
tuxcal/daemon/Makefile
tuxcom/Makefile
tuxmail/Makefile
tuxmail/daemon/Makefile
tuxwetter/Makefile
vinfo/Makefile
])

AC_OUTPUT
