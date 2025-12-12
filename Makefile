PREFIX ?= /usr/share/tuxbox/neutrino
PLUGIN_SUBDIR ?= plugins
LUAPLUGIN_SUBDIR ?= luaplugins
ICONSDIR ?= /usr/share/tuxbox/neutrino/icons/
ICONSDIR_VAR ?= /var/tuxbox/icons/

PROGRAM_PREFIX ?=
PROGRAM_SUFFIX ?=
PROGRAM_TRANSFORM_NAME ?=

PLUGIN_NAME := neutrino-mediathek
PLUGIN_DIR  :=
LUAPLUGIN_DIR :=
ifneq ($(PLUGIN_SUBDIR),)
PLUGIN_DIR := $(PREFIX)/$(PLUGIN_SUBDIR)
endif
ifneq ($(LUAPLUGIN_SUBDIR),)
LUAPLUGIN_DIR := $(PREFIX)/$(LUAPLUGIN_SUBDIR)
endif

PLUGIN_SRC := neutrino-mediathek
PLUGIN_LUA := neutrino-mediathek.lua
PLUGIN_CFG := neutrino-mediathek.cfg
PLUGIN_HINT := neutrino-mediathek_hint.png

INSTALL ?= install
CP ?= cp
SED ?= sed
MV ?= mv
RM ?= rm -f
RMR ?= rm -rf
MKDIR ?= install -d
RUNTIME_ROOT ?= $(CURDIR)/../../root
RUNTIME_HOST ?=
RUNTIME_SSH ?= ssh

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

define install_target
@set -e; \
$(call compute_names); \
if [ -n "$1" ]; then \
	$(MKDIR) "$1"; \
	$(MKDIR) "$1/$$dir_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_LUA)" "$1/$$lua_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_CFG)" "$1/$$cfg_dst"; \
	$(INSTALL) -m 0644 "$(PLUGIN_HINT)" "$1/$$hint_dst"; \
	$(CP) -a "$(PLUGIN_SRC)"/. "$1/$$dir_dst/"; \
	for file in mt_images.lua mt_config.lua; do \
		$(SED) -e 's#@ICONSDIR@#$(ICONSDIR)#g' \
		-e 's#@ICONSDIR_VAR@#$(ICONSDIR_VAR)#g' \
		"$1/$$dir_dst/$$file" > "$1/$$dir_dst/$$file.tmp"; \
		$(MV) "$1/$$dir_dst/$$file.tmp" "$1/$$dir_dst/$$file"; \
	done; \
fi
endef

define uninstall_target
@set -e; \
$(call compute_names); \
if [ -n "$1" ]; then \
	$(RM) "$1/$$lua_dst"; \
	$(RM) "$1/$$cfg_dst"; \
	$(RM) "$1/$$hint_dst"; \
	$(RM) -r "$1/$$dir_dst"; \
fi
endef

install:
ifeq ($(strip $(PLUGIN_DIR)),)
	@true
else
	$(call install_target,$(DESTDIR)$(PLUGIN_DIR))
endif
ifneq ($(strip $(LUAPLUGIN_DIR)),)
ifneq ($(strip $(LUAPLUGIN_DIR)),$(strip $(PLUGIN_DIR)))
	$(call install_target,$(DESTDIR)$(LUAPLUGIN_DIR))
endif
endif

uninstall:
ifeq ($(strip $(PLUGIN_DIR)),)
	@true
else
	$(call uninstall_target,$(DESTDIR)$(PLUGIN_DIR))
endif
ifneq ($(strip $(LUAPLUGIN_DIR)),)
ifneq ($(strip $(LUAPLUGIN_DIR)),$(strip $(PLUGIN_DIR)))
	$(call uninstall_target,$(DESTDIR)$(LUAPLUGIN_DIR))
endif
endif

runtime-clean:
	@set -e; \
	$(call compute_names); \
	roots="$(RUNTIME_ROOT)"; \
	if [ -n "$$roots" ]; then \
		for r in $$roots; do \
			for base in /usr/var/tuxbox/plugins /usr/var/tuxbox/luaplugins /usr/share/tuxbox/neutrino/plugins /usr/share/tuxbox/neutrino/luaplugins; do \
				$(RMR) "$$r$$base/$$lua_dst" "$$r$$base/$$cfg_dst" "$$r$$base/$$hint_dst" "$$r$$base/$$dir_dst"; \
			done; \
		done; \
	fi; \
	if [ -n "$(RUNTIME_HOST)" ]; then \
		$(RUNTIME_SSH) $(RUNTIME_HOST) "for base in /var/tuxbox/plugins /var/tuxbox/luaplugins /usr/share/tuxbox/neutrino/plugins /usr/share/tuxbox/neutrino/luaplugins; do rm -rf \"\$${base}/$$lua_dst\" \"\$${base}/$$cfg_dst\" \"\$${base}/$$hint_dst\" \"\$${base}/$$dir_dst\"; done"; \
	fi

clean:
	@echo "Nothing to clean"

.PHONY: all install uninstall clean runtime-clean
