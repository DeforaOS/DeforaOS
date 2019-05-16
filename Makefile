#$Id$
#Copyright (c) 2004-2019 Pierre Pronchery <khorben@defora.org>
#This file is part of the DeforaOS Project



#variables
PACKAGE	= DeforaOS
VERSION	= 0.0.0
SUBDIRS	= System/src Apps Library
PREFIX	= /usr/local
DEVNULL	= /dev/null
EXEEXT	=
TGZEXT	= .tar.gz
#executables
BUILDSH	= ./build.sh -v
CONFIGURE= ./Apps/Devel/src/configure/configure-git/src/configure$(EXEEXT)
RM	= rm -f
TAR	= tar
MKDIR	= mkdir -m 0755 -p


all:
	@if [ ! -x "$(CONFIGURE)" ]; then \
		$(MAKE) bootstrap; \
	else \
		$(MAKE) subdirs; \
	fi

subdirs:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE)) || exit; done

bootstrap:
	$(BUILDSH) -O MAKE="$(MAKE)" -O PREFIX="$(PREFIX)" bootstrap

clean:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE) clean) || exit; done

dist:
	#XXX hack to bootstrap only configure
	$(BUILDSH) -O MAKE="$(MAKE)" bootstrap < "$(DEVNULL)"
	$(CONFIGURE) -v
	$(MAKE) dist

distcheck: dist
	$(TAR) -xzvf $(OBJDIR)$(PACKAGE)-$(VERSION)$(TGZEXT)
	$(MKDIR) -- $(PACKAGE)-$(VERSION)/objdir
	$(MKDIR) -- $(PACKAGE)-$(VERSION)/destdir
	#TODO actually perform checks
	$(RM) -r -- $(PACKAGE)-$(VERSION)

distclean:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE) distclean) || exit; done

install:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE) install) || exit; done

uninstall:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE) uninstall) || exit; done

.PHONY: all subdirs clean dist distcheck distclean install uninstall bootstrap
