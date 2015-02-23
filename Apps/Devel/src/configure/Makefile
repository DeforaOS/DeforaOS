PACKAGE	= configure
VERSION	= git
TARGETS	= build configure download extract patch
OBJDIR	=
PREFIX	= /usr/local
DESTDIR	=
RM	= rm -f
LN	= ln -f
TAR	= tar
MKDIR	= mkdir -m 0755 -p
INSTALL	= install


all: $(TARGETS)

build: configure
	../script.sh -P "$(PREFIX)" -- "build"

configure: patch
	../script.sh -P "$(PREFIX)" -- "configure"

download:
	../script.sh -O URL=http://git.defora.org/DeforaOS/$(PACKAGE).git -P "$(PREFIX)" -- "download"

extract: download
	../script.sh -P "$(PREFIX)" -- "extract"

patch: extract
	../script.sh -P "$(PREFIX)" -- "patch"

clean:
	$(RM) -- $(build_OBJS) $(configure_OBJS) $(download_OBJS) $(extract_OBJS) $(patch_OBJS)
	../script.sh -c -P "$(PREFIX)" -- "build"
	../script.sh -c -P "$(PREFIX)" -- "configure"
	../script.sh -O URL=http://git.defora.org/DeforaOS/$(PACKAGE).git -c -P "$(PREFIX)" -- "download"
	../script.sh -c -P "$(PREFIX)" -- "extract"
	../script.sh -c -P "$(PREFIX)" -- "patch"

distclean: clean
	$(RM) -- $(TARGETS)

dist:
	$(RM) -r -- $(OBJDIR)$(PACKAGE)-$(VERSION)
	$(LN) -s -- "$$PWD" $(OBJDIR)$(PACKAGE)-$(VERSION)
	@cd $(OBJDIR). && $(TAR) -czvf $(OBJDIR)$(PACKAGE)-$(VERSION).tar.gz -- \
		$(PACKAGE)-$(VERSION)/Makefile \
		$(PACKAGE)-$(VERSION)/config.sh \
		$(PACKAGE)-$(VERSION)/project.conf
	$(RM) -- $(OBJDIR)$(PACKAGE)-$(VERSION)

distcheck: dist
	$(TAR) -xzvf $(OBJDIR)$(PACKAGE)-$(VERSION).tar.gz
	$(MKDIR) -- $(PACKAGE)-$(VERSION)/objdir
	$(MKDIR) -- $(PACKAGE)-$(VERSION)/destdir
	(cd "$(PACKAGE)-$(VERSION)" && $(MAKE) OBJDIR="$$PWD/objdir/")
	(cd "$(PACKAGE)-$(VERSION)" && $(MAKE) OBJDIR="$$PWD/objdir/" DESTDIR="$$PWD/destdir" install)
	(cd "$(PACKAGE)-$(VERSION)" && $(MAKE) OBJDIR="$$PWD/objdir/" DESTDIR="$$PWD/destdir" uninstall)
	(cd "$(PACKAGE)-$(VERSION)" && $(MAKE) OBJDIR="$$PWD/objdir/" distclean)
	(cd "$(PACKAGE)-$(VERSION)" && $(MAKE) dist)
	$(RM) -r -- $(PACKAGE)-$(VERSION)

install: $(TARGETS)
	../script.sh -P "$(DESTDIR)$(PREFIX)" -i -- "build"

uninstall:
	../script.sh -P "$(DESTDIR)$(PREFIX)" -u -- "build"

.PHONY: all clean distclean dist distcheck install uninstall build configure download extract patch
