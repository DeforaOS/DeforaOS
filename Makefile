#$Id$
#Copyright (c) 2004-2016 Pierre Pronchery <khorben@defora.org>
#This file is part of the DeforaOS Project



SUBDIRS	= System/src Apps Library
PREFIX	= /usr/local
DEVNULL	= /dev/null
EXEEXT	=
BUILDSH	= ./build.sh -v
CONFIGURE= ./Apps/Devel/src/configure/configure-git/src/configure$(EXEEXT)


all:
	@if [ ! -x "$(CONFIGURE)" ]; then \
		$(MAKE) bootstrap; \
	else \
		$(MAKE) subdirs; \
	fi

subdirs:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE)) || exit; done

bootstrap:
	./build.sh -v -O MAKE="$(MAKE)" -O PREFIX="$(PREFIX)" bootstrap

clean:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE) clean) || exit; done

dist:
	#XXX hack to bootstrap only configure
	$(BUILDSH) -O MAKE="$(MAKE)" bootstrap < "$(DEVNULL)"
	$(CONFIGURE) -v
	$(MAKE) dist

distclean:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE) distclean) || exit; done

install:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE) install) || exit; done

uninstall:
	@for i in $(SUBDIRS); do (cd $$i && $(MAKE) uninstall) || exit; done

.PHONY: all subdirs bootstrap clean dist distclean install uninstall
