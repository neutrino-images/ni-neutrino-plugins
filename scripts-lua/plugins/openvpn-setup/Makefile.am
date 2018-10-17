install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(PLUGINDIR)/openvpn-setup
	install -m 0644 $(srcdir)/openvpn-setup.cfg $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/openvpn-setup.lua $(DESTDIR)$(PLUGINDIR)
	install -m 0755 $(srcdir)/ovpn.init $(DESTDIR)/etc/init.d/ovpn
	cp -a $(srcdir)/openvpn-setup/ $(DESTDIR)$(PLUGINDIR)/
