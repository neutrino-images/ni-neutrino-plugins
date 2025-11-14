PREFIX ?= /usr/share/tuxbox/neutrino
PLUGIN_SUBDIR ?= plugins
LUAPLUGIN_SUBDIR ?= luaplugins

PROGRAM_PREFIX ?=
PROGRAM_SUFFIX ?=
PROGRAM_TRANSFORM_NAME ?=

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

define compute_names
name='$(PLUGIN_NAME)'; \
name="$(PROGRAM_PREFIX)$${name}$(PROGRAM_SUFFIX)"; \
if [ -n "$(PROGRAM_TRANSFORM_NAME)" ]; then \
	name=$$(printf '%s' "$$name" | sed '$(PROGRAM_TRANSFORM_NAME)'); \
fi; \
lua_dst="$$name.lua"; \
cfg_dst="$$name.cfg"; \
hint_dst="$${name}_hint.png"; \
dir_dst="$$name"
endef

install:
	@set -e; \
	$(call compute_names); \
	$(MKDIR) "$(DESTDIR)$(PLUGIN_DIR)"; \
	$(MKDIR) "$(DESTDIR)$(PLUGIN_DIR)/$$dir_dst"; \
	$(MKDIR) "$(DESTDIR)$(LUAPLUGIN_DIR)"; \
	$(MKDIR) "$(DESTDIR)$(LUAPLUGIN_DIR)/$$dir_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_LUA)" "$(DESTDIR)$(PLUGIN_DIR)/$$lua_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_LUA)" "$(DESTDIR)$(LUAPLUGIN_DIR)/$$lua_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_CFG)" "$(DESTDIR)$(PLUGIN_DIR)/$$cfg_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_CFG)" "$(DESTDIR)$(LUAPLUGIN_DIR)/$$cfg_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_HINT)" "$(DESTDIR)$(PLUGIN_DIR)/$$hint_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_HINT)" "$(DESTDIR)$(LUAPLUGIN_DIR)/$$hint_dst"; \
	$(CP) -a "$(PLUGIN_SRC)"/. "$(DESTDIR)$(PLUGIN_DIR)/$$dir_dst/"; \
	$(CP) -a "$(PLUGIN_SRC)"/. "$(DESTDIR)$(LUAPLUGIN_DIR)/$$dir_dst/"

uninstall:
	@set -e; \
	$(call compute_names); \
	$(RM) "$(DESTDIR)$(PLUGIN_DIR)/$$lua_dst"; \
	$(RM) "$(DESTDIR)$(PLUGIN_DIR)/$$cfg_dst"; \
	$(RM) "$(DESTDIR)$(PLUGIN_DIR)/$$hint_dst"; \
	$(RM) "$(DESTDIR)$(LUAPLUGIN_DIR)/$$lua_dst"; \
	$(RM) "$(DESTDIR)$(LUAPLUGIN_DIR)/$$cfg_dst"; \
	$(RM) "$(DESTDIR)$(LUAPLUGIN_DIR)/$$hint_dst"; \
	$(RM) -r "$(DESTDIR)$(PLUGIN_DIR)/$$dir_dst"; \
	$(RM) -r "$(DESTDIR)$(LUAPLUGIN_DIR)/$$dir_dst"

clean:
	@echo "Nothing to clean"

.PHONY: all install uninstall clean
