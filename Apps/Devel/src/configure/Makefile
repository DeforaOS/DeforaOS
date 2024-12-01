PACKAGE	= configure
VERSION	= git
VENDOR	= DeforaOS
TARGETS	= build configure download extract patch tests
OBJDIR	=
PREFIX	= /usr/local
DESTDIR	=
RM	= rm -f
LN	= ln -f
TAR	= tar
TGZEXT	= .tar.gz
MKDIR	= mkdir -m 0755 -p
INSTALL	= install


all: build configure download extract patch

build: configure
	../../../../System/src/script.sh -P "$(PREFIX)" -- "build"

configure: patch
	../../../../System/src/script.sh -P "$(PREFIX)" -- "configure"

download:
	../../../../System/src/script.sh -P "$(PREFIX)" -O URL=https://git.defora.org/DeforaOS/$(PACKAGE).git -- "download"

extract: download
	../../../../System/src/script.sh -P "$(PREFIX)" -- "extract"

patch: extract
	../../../../System/src/script.sh -P "$(PREFIX)" -- "patch"

tests: patch
	../../../../System/src/script.sh -P "$(PREFIX)" -- "tests"

clean:
	../../../../System/src/script.sh -c -P "$(PREFIX)" -- "build"
	../../../../System/src/script.sh -c -P "$(PREFIX)" -- "configure"
	../../../../System/src/script.sh -c -P "$(PREFIX)" -O URL=https://git.defora.org/DeforaOS/$(PACKAGE).git -- "download"
	../../../../System/src/script.sh -c -P "$(PREFIX)" -- "extract"
	../../../../System/src/script.sh -c -P "$(PREFIX)" -- "patch"
	../../../../System/src/script.sh -c -P "$(PREFIX)" -- "tests"

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
	../../../../System/src/script.sh -P "$(DESTDIR)$(PREFIX)" -i -- "build"

uninstall:
	../../../../System/src/script.sh -P "$(DESTDIR)$(PREFIX)" -u -- "build"

.PHONY: all clean distclean dist distcheck install uninstall build configure download extract patch tests
