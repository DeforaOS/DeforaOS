#!/bin/sh
#$Id$
#Copyright (c) 2008-2016 Pierre Pronchery <khorben@defora.org>
#This file is part of DeforaOS
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, version 3 of the License.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.



#variables
BOOTSTRAP=
BOOTSTRAP_CFLAGS=
BOOTSTRAP_CPPFLAGS=
BOOTSTRAP_LDFLAGS=
CFLAGS=
CFLAGSF=
CPATH=
CPPFLAGS=
CPPFLAGSF=
EXEEXT=
LDFLAGS=
LDFLAGSF=
DESTDIR=
EXEEXT=
HOST=
IMAGE_FILE=
IMAGE_TYPE=
MACHINE=
PKG_CONFIG_LIBDIR=
PKG_CONFIG_PATH=
PKG_CONFIG_SYSROOT_DIR=
PREFIX=
PROGNAME="build.sh"
SOEXT=
SYSTEM=
TARGET=
TARGET_MACHINE=
TARGET_SYSTEM=
VENDOR="DeforaOS"
VERBOSE=0

#executables
CAT="cat"
CC=
CHMOD="chmod"
CHOWN="chown"
CONFIGURE=
DD="dd bs=1024"
DEBUG=
INSTALL="install"
LD=
LN="ln -f"
MAKE="make"
MKDIR="mkdir -m 0755 -p"
MKNOD="mknod"
MV="mv -f"
RMDIR="rmdir -p"
SUDO=

#internals
DEVNULL="/dev/null"
DEVZERO="/dev/zero"
SUBDIRS="System/src/libc
	System/src/libSystem
	System/src/libApp
	System/src/Loader
	System/src/Init
	System/src/Splasher
	System/src/VFS
	Apps/Unix/src/sh
	Apps/Unix/src/utils
	Apps/Unix/src/devel
	Apps/Unix/src/others
	Apps/Servers/src/inetd
	Apps/Network/src/VPN
	Apps/Devel/src/configure"


#functions
#check
check()
{
	USAGE="$1"
	EMPTY=

	shift
	for i in $@; do
		VAR=$(eval echo "\\\$\$i")
		[ -z "$VAR" ] && EMPTY="$EMPTY $i"
	done
	[ -z "$EMPTY" ] && return
	_usage "$USAGE

Error:$EMPTY need to be set"
	exit $?
}


#debug
_debug()
{
	echo "$@" 1>&2
	"$@"
}


#error
_error()
{
	echo "$PROGNAME: error: $@" 1>&2
	return 2
}


#info
_info()
{
	[ "$VERBOSE" -ne 0 ] && echo "$PROGNAME: $@" 1>&2
	return 0
}


#target
_target()
{
	_MAKE="$MAKE"
	[ ! -z "$DESTDIR" ] && _MAKE="$_MAKE DESTDIR=\"$DESTDIR\""
	[ ! -z "$PREFIX" ] && _MAKE="$_MAKE PREFIX=\"$PREFIX\""
	[ ! -z "$CC" ] && _MAKE="$_MAKE CC=\"$CC\""
	[ ! -z "$CPPFLAGS" ] && _MAKE="$_MAKE CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$CPPFLAGSF" ] && _MAKE="$_MAKE CPPFLAGSF=\"$CPPFLAGSF\""
	[ ! -z "$CFLAGS" ] && _MAKE="$_MAKE CFLAGS=\"$CFLAGS\""
	[ ! -z "$CFLAGSF" ] && _MAKE="$_MAKE CFLAGSF=\"$CFLAGSF\""
	[ ! -z "$LD" ] && _MAKE="$_MAKE LD=\"$LD\""
	[ ! -z "$LDFLAGS" ] && _MAKE="$_MAKE LDFLAGS=\"$LDFLAGS\""
	[ ! -z "$LDFLAGSF" ] && _MAKE="$_MAKE LDFLAGSF=\"$LDFLAGSF\""
	while [ $# -gt 0 ]; do
		for i in $SUBDIRS; do
			_info "Making target \"$1\" in \"$i\""
			(cd "$i" && eval $_MAKE "$1")		|| return 2
		done
		shift
	done
	return 0
}


#target_all
target_all()
{
	target_install
}


#target_bootstrap
target_bootstrap()
{
	#reset parameters
	CPPFLAGS="$BOOTSTRAP_CPPFLAGS"
	CFLAGS="$BOOTSTRAP_CFLAGS"
	LDFLAGS="$BOOTSTRAP_LDFLAGS"
	CONFIGURE=
	DESTDIR=
	#build libSystem and configure
	_bootstrap_libsystem_static				|| return 2
	_bootstrap_configure_static				|| return 2
	#re-generate the Makefiles
	_bootstrap_makefiles					|| return 2
	#warn the user
	echo
	echo '================================================================='
	echo 'The source tree is now configured for your environment. Essential'
	echo 'libraries and tools will now be installed in this folder:'
	echo "\"$PREFIX\""
	echo 'You can still exit this script with the CTRL+C key combination.'
	echo 'Otherwise, press ENTER to proceed.'
	echo '================================================================='
	echo
	read ignore						|| return 0
	#build and install essential libraries and tools
	CONFIGURE=
	FAILED=
	PATH="$PATH:$PREFIX/bin"
	PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
	_bootstrap_configure					|| return 2
	_bootstrap_makefiles					|| return 2
	_bootstrap_system		|| FAILED="$FAILED System"
	_bootstrap_devel		|| FAILED="$FAILED Devel"
	_bootstrap_database		|| FAILED="$FAILED Database"
	_bootstrap_graphics		|| FAILED="$FAILED Graphics"
	_bootstrap_desktop		|| FAILED="$FAILED Desktop"
	_bootstrap_network		|| FAILED="$FAILED Network"
	_bootstrap_unix			|| FAILED="$FAILED UNIX"
	_bootstrap_documentation	|| FAILED="$FAILED Documentation"
	[ -z "$FAILED" ]					&& return 0
	echo "Failed to build:$FAILED" 1>&2
	return 2
}

_bootstrap_configure()
{
	(SUBDIRS="Apps/Devel/src/configure" _target "clean" "install") \
								|| return 2
}

_bootstrap_configure_static()
{
	(SUBDIRS="Apps/Devel/src/configure" _target "clean" "patch") \
								|| return 2
	(CPPFLAGS="-I ../../../../../../System/src/libSystem/libSystem-git/include"
	CFLAGSF="-W"
	LDFLAGSF="../../../../../../System/src/libSystem/libSystem-git/src/libSystem.a"
	SUBDIRS="Apps/Devel/src/configure/configure-git"
	_target "all")						|| return 2
}

_bootstrap_database()
{
	#bootstrap libDatabase
	(SUBDIRS="Apps/Database/src/libDatabase" _target "clean" "install") \
								|| return 2
}

_bootstrap_desktop()
{
	RET=0

	#bootstrap libDesktop
	(SUBDIRS="Apps/Desktop/src/libDesktop" _target "clean" "install") \
								|| return 2
	#build all desktop applications
	#FIXME some desktop applications depend on others being installed
	(SUBDIRS="Apps/Desktop/src" _target "clean" "all")	|| return 2
}

_bootstrap_devel()
{
	RET=0
	S="Apps/Devel/src/CPP
		Apps/Devel/src/strace"
	#FIXME we can't install CPP because of potential conflicts
	#	Apps/Devel/src/Asm
	#	Apps/Devel/src/C99"

	#build all development applications
	for i in $S; do
		(SUBDIRS="$i" _target "clean" "all")		|| RET=$?
	done
	return $RET
}

_bootstrap_documentation()
{
	#build the documentation
	(SUBDIRS="Library/Documentation/src" _target "clean" "all") \
								|| return 2
}

_bootstrap_graphics()
{
	#build all graphics applications
	(SUBDIRS="Apps/Graphics/src" _target "clean" "all")	|| return 2
}

_bootstrap_libsystem()
{
	(SUBDIRS="System/src/libSystem" _target "clean" "install") \
								|| return 2
}

_bootstrap_libsystem_static()
{
	(SUBDIRS="System/src/libSystem" _target "clean" "patch")|| return 2
	(SUBDIRS="System/src/libSystem/libSystem-git/src"
	_target "libSystem.a")					|| return 2
}

_bootstrap_makefiles()
{
	$DEBUG "Apps/Devel/src/configure/configure-git/src/configure$EXEEXT" \
		-v -p "$PREFIX" "System/src" "Apps" "Library"	|| return 2
}

_bootstrap_network()
{
	#build all network applications
	(SUBDIRS="Apps/Network/src" _target "clean" "all")	|| return 2
}

_bootstrap_scripts()
{
	(SUBDIRS="Apps/Devel/src/scripts" _target "download")	|| return 2
}

_bootstrap_system()
{
	RET=0
	SI="System/src/libSystem
		System/src/libApp
		System/src/libParser"
	SB="System/src/Init
		System/src/Splasher
		System/src/VFS"

	#bootstrap dependencies
	for i in $SI; do
		(SUBDIRS="$i" _target "clean" "install")	|| return 2
	done
	#build the other system applications
	for i in $SB; do
		(SUBDIRS="$i" _target "clean" "all")		|| RET=$?
	done
	return $RET
}

_bootstrap_unix()
{
	RET=0
	S="System/src/libc
		Apps/Unix/src/sh
		Apps/Unix/src/utils
		Apps/Unix/src/devel
		Apps/Unix/src/others
		Apps/Servers/src/inetd"

	for i in $S; do
		(SUBDIRS="$i" _target "clean" "all")		|| RET=$?
	done
	return $RET
}


#target_clean
target_clean()
{
	_target "clean"
}


#target_distclean
target_distclean()
{
	_target "distclean"
}


#target_image
target_image()
{
	_image_pre							&&
	_image_targets							&&
	_image_post
}

_image_pre()
{
	:
}

_image_targets()
{
	target_install
}

_image_post()
{
	:
}


#target_install
target_install()
{
	D="$DESTDIR"
	P="$PREFIX"
	S="$SUBDIRS"
	L="$LDFLAGS"
	PKL="$PKG_CONFIG_LIBDIR"
	PKS="$PKG_CONFIG_SYSROOT_DIR"

	[ -z "$PKG_CONFIG_LIBDIR" ] && PKG_CONFIG_LIBDIR="$D$P/lib/pkgconfig"
	[ -z "$PKG_CONFIG_SYSROOT_DIR" ] && PKG_CONFIG_SYSROOT_DIR="$D"
	export PKG_CONFIG_LIBDIR PKG_CONFIG_PATH PKG_CONFIG_SYSROOT_DIR
	for subdir in $SUBDIRS; do
		SUBDIRS="$subdir"
		case "$subdir" in
			System/src/libc)
				_target "install"		|| return 2
				;;
			*)
				C="$CC"
				[ -z "$C" ] && C="gcc"
				CC="$C -specs $D$P/lib/gcc/deforaos-gcc.specs --sysroot $D"
				_target "install"		|| return 2
				CC="$C"
				;;
		esac
	done
	SUBDIRS="$S"
	LDFLAGS="$L"
	PKG_CONFIG_LIBDIR="$PKL"
	PKG_CONFIG_SYSROOT_DIR="$PKS"
}


#target_uninstall
target_uninstall()
{
	_target "uninstall"
}


#usage
_usage()
{
	echo "Usage: $PROGNAME [-Dv][-O option=value...] target..." 1>&2
	echo "  -D	Run in debugging mode" 1>&2
	echo "  -v	Verbose mode" 1>&2
	echo "Targets:" 1>&2
	echo "  all		Build and install in a staging directory" 1>&2
	echo "  bootstrap	Bootstrap the system" 1>&2
	echo "  clean		Remove object files" 1>&2
	echo "  distclean	Remove all compiled files" 1>&2
	echo "  image		Create a specific image" 1>&2
	echo "  install	Build and install in the system" 1>&2
	echo "  uninstall	Uninstall everything" 1>&2
	if [ ! -z "$1" ]; then
		echo 1>&2
		echo "$1" 1>&2
	fi
	return 1
}


#warning
_warning()
{
	echo "$PROGNAME: warning: $@" 1>&2
	return 2
}


#main
umask 022
#parse options
while getopts "DvO:" name; do
	case "$name" in
		D)
			DEBUG="_debug"
			;;
		v)
			VERBOSE=1
			;;
		O)
			export "${OPTARG%%=*}"="${OPTARG#*=}"
			;;
		*)
			_usage
			exit $?
			;;
	esac
done
shift $((OPTIND - 1))

#detect the platform
if [ -z "$MACHINE" ]; then
	MACHINE=$(uname -m)
	case "$MACHINE" in
		arm*b|arm*l)
			MACHINE="arm"
			;;
		i?86)
			MACHINE="i386"
			;;
		x86_64)
			MACHINE="amd64"
			;;
	esac
fi
if [ -z "$SYSTEM" ]; then
	SYSTEM=$(uname -s)
	case "$SYSTEM" in
		MINGW32_NT-?.?)
			[ -z "$EXEEXT" ] && EXEEXT=".exe"
			[ -z "$SOEXT" ] && SOEXT=".dll"
			SYSTEM="Windows"
			;;
		*)
			[ -z "$SOEXT" ] && SOEXT=".so"
			;;
	esac
fi
[ -z "$HOST" ] && HOST="$SYSTEM-$MACHINE"
[ -z "$TARGET_MACHINE" ] && TARGET_MACHINE="$MACHINE"
[ -z "$TARGET_SYSTEM" ] && TARGET_SYSTEM="$SYSTEM"
[ -z "$TARGET" ] && TARGET="$TARGET_SYSTEM-$TARGET_MACHINE"

#check for bootstrap
[ -r "System/src/libSystem/libSystem-git/src/libSystem.a" ] \
	|| BOOTSTRAP="$BOOTSTRAP libsystem_static"
[ -x "Apps/Devel/src/configure/configure-git/src/configure$EXEEXT" ] \
	|| BOOTSTRAP="$BOOTSTRAP configure_static"
[ -f "Apps/Devel/src/scripts/Makefile" ] \
	|| BOOTSTRAP="$BOOTSTRAP makefiles"
[ -d "Apps/Devel/src/scripts/scripts-git" ] \
	|| BOOTSTRAP="$BOOTSTRAP scripts"

#bootstrap what needs to be
for method in $BOOTSTRAP; do
	_info "Bootstrapping component \"$method\""
	"_bootstrap_$method"
	if [ $? -ne 0 ]; then
		_error "$method: Unable to bootstrap component"
		exit $?
	fi
done

#initialize the target
[ -z "$DESTDIR" ] && DESTDIR="$PWD/destdir-$TARGET"

if [ ! -f "Apps/Devel/src/scripts/scripts-git/targets/$TARGET" ]; then
	_warning "$TARGET: Unsupported target" 1>&2
else
	. "Apps/Devel/src/scripts/scripts-git/targets/$TARGET"
fi

#initialize variables
[ -z "$PREFIX" ] && PREFIX="/usr/local"
[ -z "$CONFIGURE" ] && CONFIGURE="$PWD/Apps/Devel/src/configure/configure-git/src/configure$EXEEXT -O DeforaOS -p $PREFIX"
[ -z "$IMAGE_TYPE" ] && IMAGE_TYPE="image"
[ -z "$IMAGE_FILE" ] && IMAGE_FILE="$VENDOR-$IMAGE_TYPE.img"
[ -z "$UID" ] && UID=$(id -u)
[ -z "$GID" ] && GID=$(id -g)
[ -z "$SUDO" -a "$UID" -ne 0 ] && SUDO="sudo"

#run targets
if [ $# -lt 1 ]; then
	_usage
	exit $?
fi
while [ $# -gt 0 ]; do
	target="$1"
	shift

	case "$target" in
		all|bootstrap|clean|distclean|image|install|uninstall)
			_info "Making target \"$target\" on $TARGET"
			"target_$target"
			if [ $? -ne 0 ]; then
				_error "$target: Could not complete target"
				exit $?
			fi
			;;
		*)
			_error "$target: Unknown target"
			_usage
			exit $?
			;;
	esac
done
