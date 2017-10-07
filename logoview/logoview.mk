
## For use in buildsystem

LOGOVIEW_VER = 1.07

$(D)/logoview: | $(TARGETPREFIX)
	$(RM_PKGPREFIX)
	rm -rf $(BUILD_TMP)/logoview
	cp -frd $(SOURCE_DIR)/cst-public-plugins.tmp/logoview $(BUILD_TMP)
	cd $(BUILD_TMP)/logoview; \
		echo "#define LV_VERSION \"$(LOGOVIEW_VER)\"" > version.h; \
		$(MAKE) all \
			CFLAGS_="$(TARGET_CFLAGS) -I$(SOURCE_DIR)/neutrino-hd/lib/libconfigfile" \
			LDFLAGS_="$(TARGET_LDFLAGS)" \
			LD_ADD="$(BUILD_TMP)/neutrino-hd/lib/libconfigfile/libtuxbox-configfile.a" \
			CC=$(TARGET)-gcc \
			STRIP=$(TARGET)-strip \
			PLATFORM=$(PLATFORM) && \
		mkdir -p $(PKGPREFIX)/bin; \
		cp logoview $(PKGPREFIX)/bin
	PKG_VER=$(LOGOVIEW_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/logoview
	rm -rf $(BUILD_TMP)/logoview
	$(RM_PKGPREFIX)
	touch $@
