#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
sep=;

define local-package-builder

ifeq ($($1_REPO_NAME),)
$1_REPO_NAME:=$1
endif

ifeq ($($1_VER),)
ifeq ($($1_BUILD),)
$1_VER=default
$1_BUILD=default
else
$1_VER=$$($1_BUILD)
endif
endif

ifeq ($($1_BUILD),)
$1_BUILD=$$($1_VER)
endif

ifeq ($($1_BUILDDIR),)
$1_BUILDDIR:=$(BUILDDIR)/$1/$$($1_BUILD)
endif

ifeq ($($1_BUILDDIR_TMP),)
$1_BUILDDIR_TMP:=$(BUILDDIR)/.conf/$1
endif

ifeq ($($1_CONFDIR),)
$1_CONFDIR:=$(PACKAGEDIR)/$1
endif

ifeq ($($1_PATCHESDIR),)
ifeq ($($1_PATCHES),)
$1_PATCHES=patches
endif
$1_PATCHESDIR:=$$($1_CONFDIR)/$$($1_PATCHES)
endif

# stamps are used as cookies to indicate stages of package creation

ifeq ($($1_DOWNLOAD_REPO_STAMP),)
$1_DOWNLOAD_REPO_STAMP=$(DOWNLOADDIR)/$1-download-$$($1_REPO_NAME)-repo.stamp
endif

ifeq ($($1_UPDATE_STAMP),)
$1_UPDATE_STAMP=$(DOWNLOADDIR)/$1-update-$$($1_VER).stamp
endif

ifeq ($($1_CHECKOUT_STAMP),)
$1_CHECKOUT_STAMP=$(DOWNLOADDIR)/$1-checkout-$$($1_VER).stamp
endif

ifeq ($($1_DOWNLOAD_STAMP),)
$1_DOWNLOAD_STAMP=$(DOWNLOADDIR)/$1-download-$$($1_VER).stamp
endif

ifeq ($($1_UNPACKED_STAMP),)
$1_UNPACKED_STAMP=$$($1_BUILDDIR_TMP)/.unpacked-$$($1_BUILD).stamp
endif

ifeq ($($1_PATCHED_STAMP),)
$1_PATCHED_STAMP=$$($1_BUILDDIR_TMP)/.patched-$$($1_BUILD).stamp
endif

ifeq ($($1_CONFIG_STAMP),)
$1_CONFIG_STAMP=$$($1_BUILDDIR_TMP)/.config-$$($1_BUILD).stamp
endif

ifeq ($($1_BUILD_STAMP),)
$1_BUILD_STAMP=$$($1_BUILDDIR_TMP)/.build-$$($1_BUILD).stamp
endif

ifeq ($($1_BUILDDIR_TMP_STAMP),)
$1_BUILDDIR_TMP_STAMP=$$($1_BUILDDIR_TMP)/.tmp.stamp
endif

$$($1_BUILDDIR_TMP)/.dir:
	mkdir -p $$($1_BUILDDIR_TMP)
	touch $$($1_BUILDDIR_TMP)/.dir

$$($1_BUILDDIR_TMP_STAMP): $$($1_BUILDDIR_TMP)/.dir
	if [ ! -d $$($1_BUILDDIR) ]; then \
	    mkdir -p $$($1_BUILDDIR); \
	fi
	touch $$($1_BUILDDIR_TMP_STAMP)

ifeq ($($1_REPO),)
ifneq ($($1_REPO_URL),)
$1_REPO=y
endif
endif

ifneq ($$($1_REPO),)

$$($1_DOWNLOAD_REPO_STAMP):
	if [ ! -d $(DOWNLOADDIR) ]; then \
		mkdir -p $(DOWNLOADDIR); \
	fi
ifneq ($$($1_REPO_GIT),)
	rm -rf $(DOWNLOADDIR)/$$($1_REPO_NAME)
ifneq ($($1_REPO_URL),)
	(cd $(DOWNLOADDIR); \
	  git $($1_GIT_OPTS) clone $($1_GIT_CLONE_OPTS) $($1_REPO_PREFIX)$($1_REPO_URL) $$($1_REPO_NAME); \
	  cd $$($1_REPO_NAME); git fetch --tags; \
	)
else
ifneq ($($1_REPO_GIT_TGZ),)
	(cd $(DOWNLOADDIR); \
	    mkdir -p $($1_REPO); \
	    cd $($1_REPO); \
	    tar xzf $($1_REPO_GIT_TGZ); \
	)
else
ifneq ($($1_REPO_DOWNLOAD),)
	(cd $(DOWNLOADDIR); \
	  git $($1_GIT_OPTS) clone $($1_GIT_CLONE_OPTS) $($1_REPO_PREFIX)$($1_REPO)/$($1_REPO_DOWNLOAD); \
	)
else
ifneq ($($1_REPO_ALIAS),)
	(cd $(DOWNLOADDIR); \
	  git $($1_GIT_OPTS) clone $($1_GIT_CLONE_OPTS) $($1_REPO_PREFIX)$($1_REPO)/$($1_REPO_ALIAS); \
	  mv $($1_REPO_ALIAS) $$($1_REPO_NAME); \
	  cd $$($1_REPO_NAME); git fetch --tags; \
	)
else
	(cd $(DOWNLOADDIR); \
	  git $($1_GIT_OPTS) clone $($1_GIT_CLONE_OPTS) $($1_REPO_PREFIX)$($1_REPO)/$$($1_REPO_NAME); \
	  cd $$($1_REPO_NAME); git fetch --tags; \
	)
endif
endif
endif
endif

ifneq ($($1_GIT_RESET_HARD),)
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	  git reset --hard  $($1_GIT_RESET_HARD); \
	)
endif
ifneq ($($1_REPO_GIT_PATCH),)
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	  git am $($1_REPO_GIT_PATCH); \
	)
endif

endif

ifeq ($($1_REPO_HG),y)
	rm -rf $(DOWNLOADDIR)/$$($1_REPO_NAME)
ifneq ($($1_REPO_DOWNLOAD),)
	(cd $(DOWNLOADDIR); \
	  hg clone $($1_REPO)/$($1_REPO_DOWNLOAD); \
	)
else
	(cd $(DOWNLOADDIR); \
	  hg clone $($1_REPO)/$$($1_REPO_NAME); \
	  cd $$($1_REPO_NAME); \
	)
endif
endif
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); $(foreach hook,$($1_DOWNLOAD_HOOKS),$(call $(hook))$(sep)))
	touch $$($1_DOWNLOAD_REPO_STAMP)


$$($1_UPDATE_STAMP): $$($1_DOWNLOAD_REPO_STAMP)
ifeq ($($1_REPO_GIT),y)
ifneq ($($1_REPO_DOWNLOAD),)
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	  git pull; \
	  git fetch --tags; \
	  rm -f $$($1_CHECKOUT_STAMP)
	)
endif
endif
ifeq ($($1_REPO_HG),y)
ifneq ($($1_REPO_DOWNLOAD),)
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	  hg pull -u; \
	  rm -f $$($1_CHECKOUT_STAMP)
	)
endif
endif
	touch $$($1_UPDATE_STAMP)

$$($1_CHECKOUT_STAMP): $$($1_DOWNLOAD_REPO_STAMP)
ifneq ($$($1_CHECKOUT),)
ifeq ($($1_REPO_HG),y)
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	  hg pull -u ; \
	  hg update $$($1_CHECKOUT); \
	)
endif
ifeq ($($1_REPO_GIT),y)
ifeq ($($1_REPO_GIT_NOREFRESH),y)
else
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	  git checkout master; \
	  git pull; \
	  git fetch --tags; \
	)
endif
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	  git checkout -f $$($1_CHECKOUT); \
	)
endif
endif
	(cd $(DOWNLOADDIR)/$$($1_REPO_NAME); $(foreach hook,$($1_POST_CHECKOUT_HOOKS),$(call $(hook))$(sep)))
	touch $$($1_CHECKOUT_STAMP)
endif

ifneq ($$($1_REPO),)
$$($1_DOWNLOAD_STAMP): $$($1_CHECKOUT_STAMP)
else
$$($1_DOWNLOAD_STAMP):
endif
	rm -f $(DOWNLOADDIR)/$1_$($1_VER).tgz
ifneq ($($1_REPO_GIT_FULL),)
	( \
	if [ -d $(DOWNLOADDIR)/$$($1_REPO_NAME) ]; then \
	cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	tar -czf $(DOWNLOADDIR)/$1_$($1_VER).tgz .; \
	fi \
	)
endif
ifneq ($($1_REPO_GIT),)
ifneq ($($1_REPO_GIT_FULL),)
	( \
	if [ -d $(DOWNLOADDIR)/$$($1_REPO_NAME) ]; then \
	cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	tar -czf $(DOWNLOADDIR)/$1_$($1_VER).tgz .; \
	fi \
	)
else
	( \
	if [ -d $(DOWNLOADDIR)/$$($1_REPO_NAME) ]; then \
	cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	tar --exclude='.git' -czf $(DOWNLOADDIR)/$1_$($1_VER).tgz *; \
	fi \
	)
endif
endif
ifneq ($($1_REPO_HG),)
	( \
	cd $(DOWNLOADDIR)/$$($1_REPO_NAME); \
	tar --exclude='.hg' -xzf $(DOWNLOADDIR)/$1_$($1_VER).tgz \
	)
endif
ifneq ($($1_REPO_XZ),)
	curl -L -o $(DOWNLOADDIR)/$1_$($1_VER).xz $($1_REPO_XZ)
endif
ifneq ($($1_REPO_BZ2),)
	curl -L -o $(DOWNLOADDIR)/$1_$($1_VER).bz2 $($1_REPO_BZ2)
endif
ifneq ($($1_REPO_TGZ),)
	curl -L -o $(DOWNLOADDIR)/$1_$($1_VER).tgz $($1_REPO_TGZ)
endif
ifneq ($($1_REPO_ZIP),)
	curl -L -o $(DOWNLOADDIR)/$1_$($1_VER).zip $($1_REPO_ZIP)
endif
ifneq ($($1_TGZ),)
	cp $($1_TGZ) $(DOWNLOADDIR)/$1_$($1_VER).tgz
endif
	touch $$($1_DOWNLOAD_STAMP);

$$($1_UNPACKED_STAMP): $$($1_DOWNLOAD_STAMP) $$($1_BUILDDIR_TMP_STAMP)
	if [ ! -d $$($1_BUILDDIR) ]; then \
	    mkdir -p $$($1_BUILDDIR); \
	fi
	(cd $$($1_BUILDDIR); \
	  touch $$($1_UNPACKED_STAMP); \
	  if [ -f $(DOWNLOADDIR)/$1_$($1_VER).tgz ] ; then \
	    tar xzf $(DOWNLOADDIR)/$1_$($1_VER).tgz; \
	  elif [ -f $(DOWNLOADDIR)/$1_$($1_VER).bz2 ] ; then \
	    tar xjf $(DOWNLOADDIR)/$1_$($1_VER).bz2; \
	  elif [ -f $(DOWNLOADDIR)/$1_$($1_VER).xz ] ; then \
	    tar xJf $(DOWNLOADDIR)/$1_$($1_VER).xz; \
	  elif [ -f $(DOWNLOADDIR)/$1_$($1_VER).zip ] ; then \
	    unzip $(DOWNLOADDIR)/$1_$($1_VER).zip; \
	  fi \
	 )
ifneq ($($1_BUILD_SUBDIR),)
	(cd $($1_BUILDDIR); \
	  cd .. ; \
	  mv $($1_BUILDDIR)/$($1_BUILD_SUBDIR) tmp ; \
	  rmdir $($1_BUILDDIR); \
	  mv tmp $($1_BUILDDIR); \
	)
endif
ifneq ($($1_BUILD_PATCH),)
	(cd $($1_BUILDDIR); \
	  patch -p 1 < $($1_BUILD_PATCH); \
	)
endif

$$($1_PATCHED_STAMP): $$($1_UNPACKED_STAMP)
	if [ ! -d $$($1_BUILDDIR) ]; then \
	    mkdir -p $$($1_BUILDDIR); \
	fi
	if [ -d $$($1_PATCHESDIR) ]; then \
	  rm -f $$($1_PATCHESDIR)/$($1_VER)/series; \
	  rm -f $$($1_PATCHESDIR)/series; \
	fi
	if [ -f $$($1_PATCHESDIR)/$($1_VER)/series-$(BOARD)$(VARIANT)$(SUBVARIANT)$($1_VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/series-$(BOARD)$(VARIANT)$(SUBVARIANT)$($1_VARIANT) $$($1_PATCHESDIR)/$($1_VER)/series; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/series-$(BOARD)$(VARIANT)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/series-$(BOARD)$(VARIANT)$(SUBVARIANT) $$($1_PATCHESDIR)/$($1_VER)/series; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/series-$(BOARD)$(VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/series-$(BOARD)$(VARIANT) $$($1_PATCHESDIR)/$($1_VER)/series; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/series-$(BOARD) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/series-$(BOARD) $$($1_PATCHESDIR)/$($1_VER)/series; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/series-$(SOC)$(VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/series-$(SOC)$(VARIANT) $$($1_PATCHESDIR)/$($1_VER)/series; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/series-$(SOC) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/series-$(SOC) $$($1_PATCHESDIR)/$($1_VER)/series; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/series.default ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/series.default $$($1_PATCHESDIR)/$($1_VER)/series; \
	elif [ -f $$($1_PATCHESDIR)/series-$(BOARD)$(VARIANT)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/series-$(BOARD)$(VARIANT)$(SUBVARIANT) $$($1_PATCHESDIR)/series; \
	elif [ -f $$($1_PATCHESDIR)/series-$(BOARD)$(VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/series-$(BOARD)$(VARIANT) $$($1_PATCHESDIR)/series; \
	elif [ -f $$($1_PATCHESDIR)/series-$(BOARD) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/series-$(BOARD) $$($1_PATCHESDIR)/series; \
	elif [ -f $$($1_PATCHESDIR)/series-$(SOC)$(VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/series-$(SOC)$(VARIANT) $$($1_PATCHESDIR)/series; \
	elif [ -f $$($1_PATCHESDIR)/series-$(SOC) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/series-$(SOC) $$($1_PATCHESDIR)/series; \
	elif [ -f $$($1_PATCHESDIR)/series.default ] ; then \
	  ln -sf $$($1_PATCHESDIR)/series.default $$($1_PATCHESDIR)/series; \
	else \
	echo No series file created; \
	fi;
	
	if [ -f $$($1_PATCHESDIR)/$($1_VER)/series ] ; then \
	  ln -s $$($1_PATCHESDIR)/$($1_VER) $$($1_BUILDDIR)/patches; \
	  ( cd $$($1_BUILDDIR) && quilt push -a || test $$$$? = 2 ); \
	elif [ -f $$($1_PATCHESDIR)/series ] ; then \
	  ln -s $$($1_PATCHESDIR) $$($1_BUILDDIR)/patches; \
	  ( cd $$($1_BUILDDIR) && quilt push -a || test $$$$? = 2 ); \
	else \
	  echo No patches applied; \
	fi;
	touch $$($1_PATCHED_STAMP)

$1-patched: $$($1_PATCHED_STAMP)

$$($1_CONFIG_STAMP): $$($1_PATCHED_STAMP) $$($1_CONFIG_DEPENDS)
	rm -f $$($1_BUILDDIR_TMP)/config;
	echo patches dir is $$($1_PATCHESDIR);
	if [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD)$(VARIANT)$(SUBVARIANT)$($1_VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD)$(VARIANT)$(SUBVARIANT)$($1_VARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD)$(VARIANT)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD)$(VARIANT)$(SUBVARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD)$(VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD)$(VARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD)$(SUBVARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(BOARD) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(SOC)$(VARIANT)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(SOC)$(VARIANT)$(SUBVARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(SOC)$(VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(SOC)$(VARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(SOC)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(SOC)$(SUBVARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config-$(SOC) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config-$(SOC) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/$($1_VER)/config.default ] ; then \
	  ln -sf $$($1_PATCHESDIR)/$($1_VER)/config.default $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(BOARD)$(VARIANT)$(SUBVARIANT)$($1_VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(BOARD)$(VARIANT)$(SUBVARIANT)$($1_VARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(BOARD)$(VARIANT)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(BOARD)$(VARIANT)$(SUBVARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(BOARD)$(VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(BOARD)$(VARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(BOARD)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(BOARD)$(SUBVARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(BOARD) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(BOARD) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(SOC)$(VARIANT)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(SOC)$(VARIANT)$(SUBVARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(SOC)$(VARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(SOC)$(VARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(SOC)$(SUBVARIANT) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(SOC)$(SUBVARIANT) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config-$(SOC) ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config-$(SOC) $$($1_BUILDDIR_TMP)/config; \
	elif [ -f $$($1_PATCHESDIR)/config.default ] ; then \
	  ln -sf $$($1_PATCHESDIR)/config.default $$($1_BUILDDIR_TMP)/config; \
	else \
	echo No config file created; \
	fi;
ifneq ($($1_CONFIGSCRIPT),)
	( cd $$($1_BUILDDIR) && \
	$($1_CONFIGSCRIPT)\
	)
endif
	$(foreach hook,$($1_CONFIG_HOOKS),$(call $(hook))$(sep))
	touch $$($1_CONFIG_STAMP)

$1-config: $$($1_CONFIG_STAMP)

ifneq ($($1_PREDEPENDS),)
ifeq ($($1_DEPENDS),)
$1_DEPENDS=$($1_PREDEPENDS)
else
$($1_DEPENDS): $($1_PREDEPENDS)
endif
endif

$$($1_BUILD_STAMP): $$($1_CONFIG_STAMP) $$($1_DEPENDS)
ifneq ($($1_NAME),)
	@echo "I: building $($1_NAME)"
else
	@echo "I: building $($1)"
endif

	$(foreach hook,$($1_PRE_MAKESCRIPT_HOOKS),$(call $(hook))$(sep))
ifneq ($($1_PRE_MAKESCRIPT),)
	( cd $$($1_BUILDDIR) && \
	$($1_PRE_MAKESCRIPT) \
	)
endif

ifneq ($($1_MAKESCRIPT),)
	( cd $$($1_BUILDDIR) && \
	$($1_ENV_MAKEOPTS) $($1_MAKESCRIPT) \
	)
else
	if [ -f $$($1_CONFDIR)/Makefile ]; then \
	  $($1_ENV_MAKEOPTS) $(MAKE) $($1_MAKEOPTS) -C $$($1_CONFDIR); \
	elif [ -f $$($1_BUILDDIR)/Makefile ]; then \
	  $($1_ENV_MAKEOPTS) $(MAKE) $($1_MAKEOPTS) -C $$($1_BUILDDIR); \
	fi
endif

	$(foreach hook,$($1_POST_MAKESCRIPT_HOOKS),$(call $(hook))$(sep))
ifneq ($($1_POST_MAKESCRIPT),)
	( cd $$($1_BUILDDIR) && \
	$($1_POST_MAKESCRIPT) \
	)
endif
	touch $$($1_BUILD_STAMP)
ifneq ($($1_TARGETS),)
	rm -f $($1_TARGETS)
	$(MAKE) $($1_TARGETS)
endif

# images are files built as a consequence of a basic build
ifneq ($($1_IMAGES),)
$($1_IMAGES): $$($1_BUILD_STAMP)
endif

# targets are builds that pre-depends on a build
ifneq ($($1_TARGETS),)
$($1_TARGETS): $$($1_BUILD_STAMP)
endif

$1-depends: $$($1_DEPENDS)

$1-download: $$($1_DOWNLOAD_STAMP)

$1-images: $$($1_IMAGES)

$1-targets: $$($1_TARGETS)

$1-build: $$($1_BUILD_STAMP)

$1: $$($1_BUILD_STAMP) $$($1_TARGETS)

$1-install: $1 $($1_INSTALL_DEPENDS)
	#$(foreach hook,$($1_INSTALL_HOOKS),$(call $(hook))$(sep))

$1-clean: $($1_CLEAN_DEPENDS)
	$(foreach hook,$($1_CLEAN_HOOKS),$(call $(hook))$(sep))
	rm -rf $$($1_BUILDDIR)
	rm -rf $$($1_BUILDDIR_TMP)
ifneq ($$($1_PATCHESDIR),)
ifneq ($($1_VER),)
	rm -f $$($1_PATCHESDIR)/$($1_VER)/series
endif
	rm -f $$($1_PATCHESDIR)/series
endif

$1-checkout: $$($1_CHECKOUT_STAMP)

$1-checkout-clean: $1-clean
	rm $$($1_CHECKOUT_STAMP)

$1-distclean: $1-clean $($1_DISTCLEAN_DEPENDS)
	$(foreach hook,$($1_DISTCLEAN_HOOKS),$(call $(hook))$(sep))
	rm -f $(DOWNLOADDIR)/$1*.stamp
	rm -f $(DOWNLOADDIR)/$1*.tgz
ifneq ($($1_REPO),)
	rm -rf $(DOWNLOADDIR)/$1*
endif

ifneq ($($1_ADDMAKEALL),n)
TARGETS+=$1
endif

.PHONY: $1 $1-install $1-checkout $1-checkout-clean $1-clean $1-distclean $1-patched $1-depends $1-config $1-build $1-images $1-targets

endef

#package-builder = $(call local-package-builder,$(packgename),$(call UPPERCASE,$(packagename))) 
package-builder = $(call local-package-builder,$1)

