plugindir = $(PLUGINDIR)

plugin_DATA = \
	rcu_switcher.cfg \
	rcu_switcher.lua \
	rcu_switcher_hint.png

install-exec-local:
	install -D -m 0755 $(srcdir)/rcu_switcher.init $(DESTDIR)$(sysconfdir)/init.d/rcu_switcher

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/rcu_switcher
