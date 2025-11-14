PREFIX ?= /usr/share/tuxbox/neutrino
PLUGIN_SUBDIR ?= plugins
LUAPLUGIN_SUBDIR ?= luaplugins

PLUGIN_NAME := neutrino-mediathek
PLUGIN_DIR  := $(PREFIX)/$(PLUGIN_SUBDIR)
LUAPLUGIN_DIR := $(PREFIX)/$(LUAPLUGIN_SUBDIR)

PLUGIN_SRC := neutrino-mediathek
PLUGIN_LUA := neutrino-mediathek.lua
PLUGIN_CFG := neutrino-mediathek.cfg
PLUGIN_HINT := neutrino-mediathek_hint.png

INSTALL ?= install
CP ?= cp
RM ?= rm -f
MKDIR ?= install -d

all:
	@echo "Nothing to build - Lua plugin"

install:
	$(MKDIR) $(DESTDIR)$(PLUGIN_DIR)
	$(MKDIR) $(DESTDIR)$(PLUGIN_DIR)/$(PLUGIN_NAME)
	$(MKDIR) $(DESTDIR)$(LUAPLUGIN_DIR)
	$(MKDIR) $(DESTDIR)$(LUAPLUGIN_DIR)/$(PLUGIN_NAME)
	$(INSTALL) -m 0644 $(PLUGIN_LUA) $(DESTDIR)$(PLUGIN_DIR)/
	$(INSTALL) -m 0644 $(PLUGIN_LUA) $(DESTDIR)$(LUAPLUGIN_DIR)/
	$(INSTALL) -m 0644 $(PLUGIN_CFG) $(DESTDIR)$(PLUGIN_DIR)/
	$(INSTALL) -m 0644 $(PLUGIN_CFG) $(DESTDIR)$(LUAPLUGIN_DIR)/
	$(INSTALL) -m 0644 $(PLUGIN_HINT) $(DESTDIR)$(PLUGIN_DIR)/
	$(INSTALL) -m 0644 $(PLUGIN_HINT) $(DESTDIR)$(LUAPLUGIN_DIR)/
	$(CP) -a $(PLUGIN_SRC)/. $(DESTDIR)$(PLUGIN_DIR)/$(PLUGIN_NAME)/
	$(CP) -a $(PLUGIN_SRC)/. $(DESTDIR)$(LUAPLUGIN_DIR)/$(PLUGIN_NAME)/

uninstall:
	$(RM) $(DESTDIR)$(PLUGIN_DIR)/$(PLUGIN_LUA)
	$(RM) $(DESTDIR)$(PLUGIN_DIR)/$(PLUGIN_CFG)
	$(RM) $(DESTDIR)$(PLUGIN_DIR)/$(PLUGIN_HINT)
	$(RM) $(DESTDIR)$(LUAPLUGIN_DIR)/$(PLUGIN_LUA)
	$(RM) $(DESTDIR)$(LUAPLUGIN_DIR)/$(PLUGIN_CFG)
	$(RM) $(DESTDIR)$(LUAPLUGIN_DIR)/$(PLUGIN_HINT)
	$(RM) -r $(DESTDIR)$(PLUGIN_DIR)/$(PLUGIN_NAME)
	$(RM) -r $(DESTDIR)$(LUAPLUGIN_DIR)/$(PLUGIN_NAME)

clean:
	@echo "Nothing to clean"

.PHONY: all install uninstall clean
