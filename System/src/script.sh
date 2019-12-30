#!/bin/sh
#$Id$
#Copyright (c) 2012-2019 Pierre Pronchery <khorben@defora.org>
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



#variables
DESTDIR="$PWD/destdir"
GIT_BRANCH='master'
PREFIX="/usr/local"
PROGNAME="script.sh"
TARGZEXT=".tar.gz"
URL=
#executables
[ -z "$CONFIGURE" ] && CONFIGURE='configure -v'
FETCH='wget'
GIT='git'
[ -n "$MAKE" ] || MAKE='make'
PATCH="patch"
RM='rm -f'
TAR='tar'
TOUCH='touch'


#functions
#error
_error()
{
	echo "$PROGNAME: error: $@" 1>&2
	return 2
}


#target_configure
_target_configure()
{
	if [ -f "$PACKAGE-$VERSION/autogen.sh" ]; then
		(cd "$PACKAGE-$VERSION" && ./autogen.sh)
	fi
	if [ -f "$PACKAGE-$VERSION/configure" ]; then
		(cd "$PACKAGE-$VERSION" && ./configure)
	elif [ -f "$PACKAGE-$VERSION/project.conf" ]; then
		(cd "$PACKAGE-$VERSION" && $CONFIGURE -p "$PREFIX")
	fi
}


#target
_target()
{
	target="$1"

	if [ $clean -ne 0 -a "$target" != "clean" ]; then
		_target_clean "$target"
		return $?
	fi
	case "$target" in
		all|install|uninstall)
			_target_make "$target"
			;;
		build)
			if [ $uninstall -ne 0 ]; then
				_target_make 'uninstall'
			elif [ $install -ne 0 ]; then
				_target_make 'install'
			else
				_target_make 'all'
			fi
			;;
		clean|distclean)
			[ ! -f "$PACKAGE-$VERSION/Makefile" ] \
				|| _target_make "$target"
			;;
		configure|download|extract|package|patch)
			"_target_$target"
			;;
		*)
			_usage
			exit $?
			;;
	esac
}


#target_clean
_target_clean()
{
	target="$1"

	case "$target" in
		all|build|install)
			_target "clean"
			return $?
			;;
		*)
			return 0
			;;
	esac
}


#target_download
_target_download()
{
	case "$URL" in
		git://*|http://*.git)
			if [ ! -d "$PACKAGE-$VERSION/.git" ]; then
				_warn "$URL: Repository access is not encrypted"
				$GIT clone -n "$URL" "$PACKAGE-$VERSION"
			fi
			;;
		https://*.git|*.git)
			if [ ! -d "$PACKAGE-$VERSION/.git" ]; then
				$GIT clone -n "$URL" "$PACKAGE-$VERSION"
			fi
			;;
		ftps://*|https://*)
			[ -f "$PACKAGE-$VERSION$TARGZEXT" ] || $FETCH "$URL"
			;;
		ftp://*|http://*)
			if [ ! -f "$PACKAGE-$VERSION$TARGZEXT" ]; then
				_warn "$URL: Repository access is not encrypted"
				$FETCH "$URL"
			fi
			;;
	esac
}


#target_extract
_target_extract()
{
	case "$VERSION" in
		git)
			(cd "$PACKAGE-$VERSION" && $GIT checkout "$GIT_BRANCH")
			;;
		*)
			[ -d "$PACKAGE-$VERSION" ] || $TAR -xzf "$PACKAGE-$VERSION$TARGZEXT"
			;;
	esac
}


#target_make
_target_make()
{
	(cd "$PACKAGE-$VERSION" && $MAKE "$@")
}


#target_package
_target_package()
{
	$RM -r "$DESTDIR"
	_target_make DESTDIR="$DESTDIR" 'install' &&
	(cd "$DESTDIR" && $TAR -czf - "${PREFIX##/}") \
		> "$PWD/$PACKAGE-$VERSION.pkg"
}


#target_patch
_target_patch()
{
	filename="patch-${PACKAGE}_$VERSION.diff"

	[ ! -f "$PACKAGE-$VERSION/.patch-done" ]		|| return 0
	if [ -f "$filename" ]; then
		(cd "$PACKAGE-$VERSION" && $PATCH -p1 < "../$filename") &&
			$TOUCH "$PACKAGE-$VERSION/.patch-done"
	fi
}


#usage
_usage()
{
	echo "Usage: $PROGNAME [-c|-i|-u][-O name=value...][-P prefix] target..." 1>&2
	echo "  -c	Perform the \"clean\" target" 1>&2
	echo "  -i	Perform the \"install\" target" 1>&2
	echo "  -u	Perform the \"uninstall\" target" 1>&2
	echo "Available targets:" 1>&2
	echo "  build" 1>&2
	echo "  configure" 1>&2
	echo "  download" 1>&2
	echo "  extract" 1>&2
	echo "  install" 1>&2
	echo "  package" 1>&2
	echo "  patch" 1>&2
	echo "  uninstall" 1>&2
	return 1
}


#warn
_warn()
{
	echo "$PROGNAME: warning: $@" 1>&2
}


#main
if [ ! -f ./config.sh ]; then
	_error "Must be called from a project folder (config.sh not found)"
	exit $?
fi
. ./config.sh

clean=0
install=0
uninstall=0
while getopts "ciO:P:u" name; do
	case "$name" in
		c)
			clean=1
			;;
		i)
			install=1
			;;
		O)
			export "${OPTARG%%=*}"="${OPTARG#*=}"
			;;
		P)
			PREFIX="$OPTARG"
			;;
		u)
			uninstall=1
			;;
		*)
			_usage
			exit $?
			;;
	esac
done
shift $((OPTIND - 1))
if [ $# -eq 0 ]; then
	_usage
	exit $?
fi

while [ $# -ne 0 ]; do
	target="$1"
	shift

	_target "$target"					|| exit $?
done
