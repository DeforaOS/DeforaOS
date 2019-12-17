PACKAGE	= libSystem
VERSION	= git
VENDOR	= DeforaOS
TARGETS	= build configure download extract patch
OBJDIR	=
PREFIX	= /usr/local
DESTDIR	=
RM	= rm -f
LN	= ln -f
TAR	= tar
TGZEXT	= .tar.gz
MKDIR	= mkdir -m 0755 -p
INSTALL	= install


all: $(TARGETS)

build: configure
	../script.sh -P "$(PREFIX)" -- "build"

configure: patch
	../script.sh -P "$(PREFIX)" -- "configure"

download:
	../script.sh -P "$(PREFIX)" -O URL=https://git.defora.org/DeforaOS/$(PACKAGE).git -- "download"

extract: download
	../script.sh -P "$(PREFIX)" -- "extract"

patch: extract
	../script.sh -P "$(PREFIX)" -- "patch"

clean:
	../script.sh -c -P "$(PREFIX)" -- "build"
	../script.sh -c -P "$(PREFIX)" -- "configure"
	../script.sh -c -P "$(PREFIX)" -O URL=https://git.defora.org/DeforaOS/$(PACKAGE).git -- "download"
	../script.sh -c -P "$(PREFIX)" -- "extract"
	../script.sh -c -P "$(PREFIX)" -- "patch"

distclean: clean

dist:
	$(RM) -r -- $(OBJDIR)$(PACKAGE)-$(VERSION)
	$(LN) -s -- "$$PWD" $(OBJDIR)$(PACKAGE)-$(VERSION)
	@cd $(OBJDIR). && $(TAR) -czvf $(PACKAGE)-$(VERSION)$(TGZEXT) -- \
		$(PACKAGE)-$(VERSION)/Makefile \
		$(PACKAGE)-$(VERSION)/config.sh \
		$(PACKAGE)-$(VERSION)/project.conf
	$(RM) -- $(OBJDIR)$(PACKAGE)-$(VERSION)

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
	../script.sh -P "$(DESTDIR)$(PREFIX)" -i -- "build"

uninstall:
	../script.sh -P "$(DESTDIR)$(PREFIX)" -u -- "build"

.PHONY: all clean distclean dist distcheck install uninstall build configure download extract patch
