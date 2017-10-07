TUXBOX-REMOTES = \
	getrc \
	input \
	logomask \
	logoview \
	msgbox \
	scripts-lua \
	shellexec \
	tuxcal \
	tuxcom \
	tuxmail \
	tuxwetter

update-tuxbox-remotes:
	for plugin in $(TUXBOX-REMOTES); do \
		git subtree pull --prefix=$$plugin https://github.com/tuxbox-neutrino/plugin-$$plugin.git master || exit 1; \
	done
