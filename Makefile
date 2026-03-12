PREFIX    ?= /usr
DESTDIR   ?= $(CURDIR)/dist
INSTALL_BASE := $(DESTDIR)$(PREFIX)/share/neutrino/plugins/lua
PLUGIN_DIR := $(INSTALL_BASE)/stb_startup
SOURCE_DIR := $(CURDIR)/plugin

.PHONY: install uninstall clean

install:
	@mkdir -p $(PLUGIN_DIR)
	@cp -a $(SOURCE_DIR)/* $(PLUGIN_DIR)/

uninstall:
	@rm -rf $(PLUGIN_DIR)

clean:
	@rm -rf $(DESTDIR)
