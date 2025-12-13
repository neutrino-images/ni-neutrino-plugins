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
# Allow absolute PLUGIN_DIR/LUAPLUGIN_DIR (e.g. passed from Neutrino configure via N_PLUGINDIR/N_LUAPLUGINDIR)
ifeq ($(PLUGIN_DIR),)
  ifneq ($(PLUGIN_SUBDIR),)
    PLUGIN_DIR := $(PREFIX)/$(PLUGIN_SUBDIR)
  endif
endif
ifeq ($(LUAPLUGIN_DIR),)
  ifneq ($(LUAPLUGIN_SUBDIR),)
    LUAPLUGIN_DIR := $(PREFIX)/$(LUAPLUGIN_SUBDIR)
  endif
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
LN ?= ln -sf
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

PRIMARY_DIR := $(LUAPLUGIN_DIR)
ifeq ($(strip $(PRIMARY_DIR)),)
PRIMARY_DIR := $(PLUGIN_DIR)
endif
SECONDARY_DIR :=
ifneq ($(strip $(PRIMARY_DIR)),$(strip $(PLUGIN_DIR)))
SECONDARY_DIR := $(PLUGIN_DIR)
endif

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

define link_target
@set -e; \
$(call compute_names); \
src="$(abspath $(DESTDIR)$1)"; \
dst="$2"; \
rel_prefix=""; \
if [ "$(dir $(PRIMARY_DIR))" = "$(dir $(SECONDARY_DIR))" ]; then \
	rel_prefix="../$(notdir $(PRIMARY_DIR))"; \
fi; \
if [ -n "$$dst" ]; then \
	$(MKDIR) "$$dst"; \
	$(RMR) "$$dst/$$lua_dst" "$$dst/$$cfg_dst" "$$dst/$$hint_dst" "$$dst/$$dir_dst"; \
	$(MKDIR) "$$dst/$$dir_dst"; \
	if [ -n "$$rel_prefix" ]; then \
		$(LN) "$$rel_prefix/$$lua_dst" "$$dst/$$lua_dst"; \
		$(LN) "$$rel_prefix/$$cfg_dst" "$$dst/$$cfg_dst"; \
		$(LN) "$$rel_prefix/$$hint_dst" "$$dst/$$hint_dst"; \
		$(LN) "$$rel_prefix/$$dir_dst" "$$dst/$$dir_dst"; \
	else \
		$(LN) "$$src/$$lua_dst" "$$dst/$$lua_dst"; \
		$(LN) "$$src/$$cfg_dst" "$$dst/$$cfg_dst"; \
		$(LN) "$$src/$$hint_dst" "$$dst/$$hint_dst"; \
		$(LN) "$$src/$$dir_dst" "$$dst/$$dir_dst"; \
	fi; \
fi
endef

install:
ifeq ($(strip $(PRIMARY_DIR)),)
	@true
else
	$(call install_target,$(DESTDIR)$(PRIMARY_DIR))
endif
ifneq ($(strip $(SECONDARY_DIR)),)
	$(call link_target,$(PRIMARY_DIR),$(DESTDIR)$(SECONDARY_DIR))
endif

uninstall:
ifeq ($(strip $(PRIMARY_DIR)),)
	@true
else
	$(call uninstall_target,$(DESTDIR)$(PRIMARY_DIR))
endif
ifneq ($(strip $(SECONDARY_DIR)),)
	$(call uninstall_target,$(DESTDIR)$(SECONDARY_DIR))
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
