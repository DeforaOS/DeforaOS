#$Id$
#Copyright (c) 2004-2026 Pierre Pronchery <khorben@defora.org>
#This file is part of the DeforaOS Project



#variables
PACKAGE	= DeforaOS
VERSION	= 0.0.0
VENDOR	= DeforaOS
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
	@if [ ! -x "$(CONFIGURE)" ]; then $(MAKE) bootstrap; else $(MAKE) subdirs; fi

subdirs:
	@for i in $(SUBDIRS); do (cd "$$i" && \
		if [ -n "$(OBJDIR)" ]; then \
		([ -d "$(OBJDIR)$$i" ] || $(MKDIR) -- "$(OBJDIR)$$i") && \
		$(MAKE) OBJDIR="$(OBJDIR)$$i/"; \
		else $(MAKE); fi) || exit; done

bootstrap:
	$(BUILDSH) -O MAKE="$(MAKE)" -O PREFIX="$(PREFIX)" bootstrap

build:
	@for subdir in $(SUBDIRS); do if [ -n "$(OBJDIR)" ]; then (cd $$subdir && $(MAKE) OBJDIR="$(OBJDIR)$$subdir/" build); else (cd $$subdir && $(MAKE) build); fi || break; done

configure:
	@for subdir in $(SUBDIRS); do (cd "$$subdir" && $(MAKE) configure) || break; done

download:
	@for subdir in $(SUBDIRS); do (cd "$$subdir" && $(MAKE) download) || break; done

extract:
	@for subdir in $(SUBDIRS); do (cd "$$subdir" && $(MAKE) extract) || break; done

patch:
	@for subdir in $(SUBDIRS); do (cd "$$subdir" && $(MAKE) patch) || break; done

sbom:
	@for subdir in $(SUBDIRS); do if [ -n "$(OBJDIR)" ]; then (cd $$subdir && $(MAKE) OBJDIR="$(OBJDIR)$$subdir/" sbom); else (cd $$subdir && $(MAKE) sbom); fi || break; done

tests:
	@for subdir in $(SUBDIRS); do (cd "$$subdir" && $(MAKE) tests) || break; done

clean:
	@for i in $(SUBDIRS); do (cd "$$i" && \
		if [ -n "$(OBJDIR)" ]; then \
		$(MAKE) OBJDIR="$(OBJDIR)$$i/" clean; \
		else $(MAKE) clean; fi) || exit; done

distclean:
	@for i in $(SUBDIRS); do (cd "$$i" && \
		if [ -n "$(OBJDIR)" ]; then \
		$(MAKE) OBJDIR="$(OBJDIR)$$i/" distclean; \
		else $(MAKE) distclean; fi) || exit; done

dist:
	#XXX hack to bootstrap only configure
	$(BUILDSH) -O MAKE="$(MAKE)" bootstrap < "$(DEVNULL)"
	$(CONFIGURE) -v
	$(MAKE) dist

distcheck: dist
	$(TAR) -xzvf $(OBJDIR)$(PACKAGE)-$(VERSION)$(TGZEXT)
	$(MKDIR) -- $(PACKAGE)-$(VERSION)/objdir
	$(MKDIR) -- $(PACKAGE)-$(VERSION)/destdir
	cd "$(PACKAGE)-$(VERSION)" && $(MAKE) OBJDIR="$$PWD/objdir/"
	cd "$(PACKAGE)-$(VERSION)" && $(MAKE) OBJDIR="$$PWD/objdir/" DESTDIR="$$PWD/destdir" install
	cd "$(PACKAGE)-$(VERSION)" && $(MAKE) OBJDIR="$$PWD/objdir/" DESTDIR="$$PWD/destdir" uninstall
	cd "$(PACKAGE)-$(VERSION)" && $(MAKE) OBJDIR="$$PWD/objdir/" distclean
	cd "$(PACKAGE)-$(VERSION)" && $(MAKE) dist
	$(RM) -r -- $(PACKAGE)-$(VERSION)

install: all
	@for i in $(SUBDIRS); do (cd "$$i" && \
		if [ -n "$(OBJDIR)" ]; then \
		$(MAKE) OBJDIR="$(OBJDIR)$$i/" install; \
		else $(MAKE) install; fi) || exit; done

uninstall:
	@for i in $(SUBDIRS); do (cd "$$i" && \
		if [ -n "$(OBJDIR)" ]; then \
		$(MAKE) OBJDIR="$(OBJDIR)$$i/" uninstall; \
		else $(MAKE) uninstall; fi) || exit; done

.PHONY: all subdirs clean distclean dist distcheck install uninstall bootstrap build configure download extract patch sbom tests
