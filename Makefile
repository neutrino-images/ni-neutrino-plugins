PREFIX    ?= /usr
DESTDIR   ?= $(CURDIR)/dist
INSTALL_BASE := $(DESTDIR)$(PREFIX)/share/neutrino/plugins/lua
PLUGIN_DIR := $(INSTALL_BASE)/stb_startup

.PHONY: install uninstall clean

install:
	@mkdir -p $(PLUGIN_DIR)
	@cp -a $(CURDIR)/stb_startup/* $(PLUGIN_DIR)/

uninstall:
	@rm -rf $(PLUGIN_DIR)

clean:
	@rm -rf $(DESTDIR)
