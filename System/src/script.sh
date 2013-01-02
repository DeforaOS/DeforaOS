#!/bin/sh



#variables
DESTDIR="$PWD/destdir"
EXT=".tar.gz"
PREFIX="/usr/local"
#executables
FETCH='wget'
GIT='git'
MAKE='make'
RM='rm -f'
TAR='tar'

. ./config.sh


#functions
#target_download
_target_download()
{
	case "$URL" in
		git://*|http://*.git|https://*.git|*.git)
			if [ ! -d "$PACKAGE-$VERSION/.git" ]; then
				$GIT clone "$URL" "$PACKAGE-$VERSION"
			else
				(cd "$PACKAGE-$VERSION" && $GIT pull --rebase) || true
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
	(cd "$DESTDIR" && $TAR -czf - "${PREFIX##/}") > "$PWD/$PACKAGE-$VERSION.pkg"
}


#target_patch
_target_patch()
{
}


#usage
_usage()
{
	echo "Usage: script.sh build|download|extract|package" 1>&2
	return 1
}


#main
install=0
uninstall=0
while getopts "iO:P:u" name; do
	case "$name" in
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

if [ $# -ne 1 ]; then
	_usage
	exit $?
fi
case "$1" in
	all|clean|distclean|install|uninstall)
		_target_make "$1"
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
	download|extract|patch)
		"_target_$1"
		;;
	package)
		_target_package
		;;
	*)
		_usage
		exit $?
		;;
esac
