locale = \
	deutsch.lua \
	english.lua

sort-locale:
	cd plugins/neutrino-mediathek/locale && \
	for language in $(locale); do \
		LC_ALL=C sort -u -o $${language} $${language} ; \
	done
