SUBDIRS = openvpn-setup

plugindir = $(PLUGINDIR)

plugin_DATA = \
	openvpn-setup.cfg \
	openvpn-setup.lua

install-exec-local:
	install -D -m 0755 $(srcdir)/ovpn.init $(DESTDIR)/etc/init.d/ovpn
