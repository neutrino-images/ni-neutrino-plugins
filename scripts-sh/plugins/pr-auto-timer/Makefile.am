plugindir = $(PLUGINDIR)

plugin_DATA = \
	pr-auto-timer.cfg \
	pr-auto-timer_hint.png	

plugin_SCRIPTS = \
	auto-record-cleaner \
	pr-auto-timer \
	pr-auto-timer.sh

configdir = $(CONFIGDIR)

config_DATA = \
	auto-record-cleaner.conf.template \
	auto-record-cleaner.rules.template \
	pr-auto-timer.conf.template \
	pr-auto-timer.rules.template

install-data-hook:
	set -e; cd $(DESTDIR)$(configdir); \
		mv auto-record-cleaner.conf.template auto-record-cleaner.conf; \
		mv auto-record-cleaner.rules.template auto-record-cleaner.rules; \
		mv pr-auto-timer.conf.template pr-auto-timer.conf; \
		mv pr-auto-timer.rules.template pr-auto-timer.rules
	
uninstall-hook:
	set -e; cd $(DESTDIR)$(configdir); \
		rm -f auto-record-cleaner.conf; \
		rm -f auto-record-cleaner.rules; \
		rm -f pr-auto-timer.conf; \
		rm -f pr-auto-timer.rules
