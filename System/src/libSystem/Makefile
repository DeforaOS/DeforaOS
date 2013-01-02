PACKAGE	= libSystem
VERSION	= git
TARGETS	= build download extract patch
PREFIX	= /usr/local
DESTDIR	=
RM	?= rm -f
LN	?= ln -f
TAR	?= tar -czvf
MKDIR	?= mkdir -p
INSTALL	?= install


all: $(TARGETS)

build: patch
	../script.sh -P "$(PREFIX)" -- "build"

download:
	../script.sh -O URL=git://github.com/DeforaOS/$(PACKAGE).git -P "$(PREFIX)" -- "download"

extract: download
	../script.sh -P "$(PREFIX)" -- "extract"

patch: extract
	../script.sh -P "$(PREFIX)" -- "patch"

clean:
	$(RM) -- $(build_OBJS) $(download_OBJS) $(extract_OBJS) $(patch_OBJS)

distclean: clean
	$(RM) -- $(TARGETS)

dist:
	$(RM) -r -- $(PACKAGE)-$(VERSION)
	$(LN) -s -- . $(PACKAGE)-$(VERSION)
	@$(TAR) $(PACKAGE)-$(VERSION).tar.gz -- \
		$(PACKAGE)-$(VERSION)/Makefile \
		$(PACKAGE)-$(VERSION)/config.sh \
		$(PACKAGE)-$(VERSION)/project.conf
	$(RM) -- $(PACKAGE)-$(VERSION)

install: $(TARGETS)
	../script.sh -P "$(DESTDIR)$(PREFIX)" -i -- "build"

uninstall:
	../script.sh -P "$(DESTDIR)$(PREFIX)" -u -- "build"

.PHONY: all clean distclean dist install uninstall
