locale = \
	deutsch.lua \
	english.lua

sort-locale:
	cd coolithek/locale && \
	for language in $(locale); do \
		LC_ALL=C sort -u -o $${language} $${language} ; \
	done
	