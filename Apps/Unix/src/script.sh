#!/bin/sh
#$Id$
#Copyright (c) 2012-2013 Pierre Pronchery <khorben@defora.org>
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
EXT=".tar.gz"
PREFIX="/usr/local"
#executables
[ -z "$CONFIGURE" ] && CONFIGURE='configure -v'
FETCH='wget'
GIT='git'
[ -n "$MAKE" ] || MAKE="make"
RM='rm -f'
TAR='tar'


#functions
#target_configure
_target_configure()
{
	if [ -f "$PACKAGE-$VERSION/configure" ]; then
		(cd "$PACKAGE-$VERSION" && ./configure)
	elif [ -f "$PACKAGE-$VERSION/project.conf" ]; then
		(cd "$PACKAGE-$VERSION" && $CONFIGURE -p "$PREFIX")
	fi
}


#target_download
_target_download()
{
	case "$URL" in
		git://*|http://*.git|https://*.git|*.git)
			if [ ! -d "$PACKAGE-$VERSION/.git" ]; then
				$GIT clone "$URL" "$PACKAGE-$VERSION"
			else
				(cd "$PACKAGE-$VERSION" && $GIT pull) || true
			fi
			;;
		ftp://*|http://*|https://*)
			[ ! -f "$PACKAGE-$VERSION$EXT" ] && $FETCH "$URL"
			;;
	esac
}


#target_extract
_target_extract()
{
	case "$URL" in
		git://*)
			;;
		http://*)
			$TAR -xzf "$PACKAGE-$VERSION$EXT"
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
	_target_make DESTDIR="$DESTDIR" install &&
	(cd "$DESTDIR" && $TAR -czf - "${PREFIX##/}") \
		> "$PWD/$PACKAGE-$VERSION.pkg"
}


#target_patch
_target_patch()
{
	:
}


#usage
_usage()
{
	echo "Usage: script.sh [-c|-i|-u][-O name=value...][-P prefix] target..." 1>&2
	echo "Available targets:" 1>&2
	echo "  build" 1>&2
	echo "  configure" 1>&2
	echo "  download" 1>&2
	echo "  extract" 1>&2
	echo "  package" 1>&2
	echo "  patch" 1>&2
	return 1
}


#main
if [ ! -f ./config.sh ]; then
	echo "script.sh: Must be called from a project folder (config.sh not found)" 1>&2
	exit 2
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

	if [ $clean -ne 0 ]; then
		target="clean"
		[ ! -d "$PACKAGE-$VERSION" ] && continue
	fi
	case "$target" in
		all|clean|distclean|install|uninstall)
			_target_make "$target"
			;;
		build)
			if [ $uninstall -ne 0 ]; then
				_target_make 'uninstall'
			elif [ $install -ne 0 ]; then
				_target_make 'install'
			else
				_target_make all
			fi
			;;
		configure|download|extract|patch)
			"_target_$target"
			;;
		package)
			_target_package
			;;
		*)
			_usage
			exit $?
			;;
	esac
done
