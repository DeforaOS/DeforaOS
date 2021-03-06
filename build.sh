#!/bin/sh
#$Id$
#Copyright (c) 2008-2019 Pierre Pronchery <khorben@defora.org>
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
CPATH=
CPPFLAGS=
DESTDIR=
EXEEXT=
LDFLAGS=
#XXX remove
LDFLAGSF=
EXEEXT=
HOST=
IMAGE_FILE=
IMAGE_TYPE=
MACHINE=
OBJDIR=
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
TOOLDIR=
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
	System/src/libMarshall
	System/src/libApp
	System/src/AppInterfaces
	System/src/libParser
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
	while [ $# -gt 0 ]; do
		target="$1"
		shift

		for subdir in $SUBDIRS; do
			objdir="$OBJDIR"

			if [ -n "$objdir" ]; then
				$MKDIR -- "$objdir/$subdir"	|| return 2
				objdir="$objdir/$subdir"
			fi
			(OBJDIR="$objdir" \
			_target_subdir "$target" "$subdir")	|| return 2
		done
	done
	return 0
}

_target_subdir()
{
	target="$1"
	subdir="$2"
	make="$MAKE"

	_info "Making target \"$target\" in \"$subdir\""
	[ -n "$CONFIGURE" ] && make="CONFIGURE=\"$CONFIGURE\" $make DESTDIR=\"$DESTDIR\""
	[ -n "$DESTDIR" ] && make="$make DESTDIR=\"$DESTDIR\""
	[ -n "$PREFIX" ] && make="$make PREFIX=\"$PREFIX\""
	[ -n "$CC" ] && make="$make CC=\"$CC\""
	[ -n "$CPPFLAGS" ] && make="$make CPPFLAGS=\"$CPPFLAGS\""
	[ -n "$CFLAGS" ] && make="$make CFLAGS=\"$CFLAGS\""
	[ -n "$LD" ] && make="$make LD=\"$LD\""
	[ -n "$LDFLAGS" ] && make="$make LDFLAGS=\"$LDFLAGS\""
	[ -n "$LDFLAGSF" ] && make="$make LDFLAGSF=\"$LDFLAGSF\""
	[ -n "$OBJDIR" ] && make="$make OBJDIR=\"$OBJDIR/\""
	(cd "$subdir" && eval $make "$target")
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
	DESTDIR=
	#build libSystem and configure
	(CONFIGURE= _bootstrap_libsystem_static)		|| return 2
	(CONFIGURE= _bootstrap_configure_static)		|| return 2
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
	FAILED=
	_bootstrap_wrap libsystem				|| return 2
	_bootstrap_wrap configure				|| return 2
	_bootstrap_wrap makefiles				|| return 2
	_bootstrap_wrap system		|| FAILED="$FAILED System"
	_bootstrap_wrap devel		|| FAILED="$FAILED Apps/Devel"
	_bootstrap_wrap database	|| FAILED="$FAILED Apps/Database"
	_bootstrap_wrap graphics	|| FAILED="$FAILED Apps/Graphics"
	_bootstrap_wrap desktop		|| FAILED="$FAILED Apps/Desktop"
	_bootstrap_wrap network		|| FAILED="$FAILED Apps/Network"
	_bootstrap_wrap unix		|| FAILED="$FAILED Apps/UNIX"
	_bootstrap_wrap web		|| FAILED="$FAILED Apps/Web"
	_bootstrap_wrap documentation	|| FAILED="$FAILED Library/Documentation"
	[ -z "$FAILED" ]					&& return 0
	echo "Failed to build:$FAILED" 1>&2
	return 2
}

_bootstrap_configure()
{
	(SUBDIRS="Apps/Devel/src/configure" \
	_target "clean" "install")				|| return 2
}

_bootstrap_configure_static()
{
	(SUBDIRS="Apps/Devel/src/configure" OBJDIR= _target "clean" "patch") \
								|| return 2
	#XXX _target_subdir() should not be visible
	(DESTDIR= \
	PREFIX="$TOOLDIR" \
	OBJDIR= \
	_target_subdir "install" "Apps/Devel/src/configure/configure-git/data") \
								|| return 2
	(DESTDIR= \
	PREFIX="$TOOLDIR" \
	CPPFLAGS="-I $TOOLDIR/include" \
	LDFLAGSF="$OBJDIR/System/src/libSystem/libSystem-git/src/libSystem.a" \
	OBJDIR= \
	_target_subdir "install" "Apps/Devel/src/configure/configure-git/src") \
								|| return 2
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
	S="Apps/Desktop/src/libDesktop
		Apps/Desktop/src/Browser
		Apps/Desktop/src/Locker
		Apps/Desktop/src/Mailer
		Apps/Desktop/src/Panel
		Apps/Desktop/src/Phone
		Apps/Desktop/src/Surfer"

	#bootstrap dependencies
	for i in $S; do
		(SUBDIRS="$i" _target "clean" "install")	|| return 2
	done
	#build all desktop applications
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
	(SUBDIRS="System/src/libSystem" \
	_target "clean" "install")				|| return 2
}

_bootstrap_libsystem_static()
{
	subdir="System/src/libSystem/libSystem-git"

	(SUBDIRS="System/src/libSystem" _target "clean" "patch")|| return 2
	(DESTDIR= \
	PREFIX="$TOOLDIR" \
	SUBDIRS="$subdir/include $subdir/data" \
	_target "install")					|| return 2
	(DESTDIR= \
	PREFIX="$TOOLDIR" \
	SUBDIRS="$subdir/src" \
	_target "$OBJDIR/$subdir/src/libSystem.a")		|| return 2
}

_bootstrap_makefiles()
{
	$DEBUG "$TOOLDIR/bin/configure$EXEEXT" -v -p "$PREFIX" \
		"System/src" "Apps" "Library"			|| return 2
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
		System/src/libMarshall
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

_bootstrap_web()
{
	#build all web applications
	(SUBDIRS="Apps/Web/src" _target "clean" "all")		|| return 2
}

_bootstrap_wrap()
{
	method="$1"
	path="$PATH"
	pc_path="$PREFIX/lib/pkgconfig"

	[ "$TARGET" != "$HOST" ] && path="$path:$PREFIX/bin"
	(PATH="$path" \
	PKG_CONFIG_PATH="$pc_path" \
	"_bootstrap_$method")					|| return 2
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
	pc_libdir="$PKG_CONFIG_LIBDIR"
	pc_sysroot_dir="$PKG_CONFIG_SYSROOT_DIR"

	[ -z "$pc_libdir" ] && pc_libdir="$DESTDIR$PREFIX/lib/pkgconfig"
	[ -z "$pc_sysroot_dir" ] && pc_sysroot_dir="$DESTDIR"
	(PKG_CONFIG_LIBDIR="$pc_libdir" \
	PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
	PKG_CONFIG_SYSROOT_DIR="$pc_sysroot_dir" \
	_install_do)						|| return 2
}

_install_do()
{
	cc="$CC"

	[ -z "$cc" ] && cc="gcc"
	cc="$DESTDIR$PREFIX/bin/deforaos-gcc --sysroot \"$DESTDIR\""
	for subdir in $SUBDIRS; do
		case "$subdir" in
			System/src/libc)
				(SUBDIRS="$subdir" \
				_target "install")		|| return 2
				;;
			*)
				(SUBDIRS="$subdir" \
				CC="$cc" _target "install")	|| return 2
				;;
		esac
	done
	return 0
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
	if [ -n "$1" ]; then
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
			eval "${OPTARG%%=*}"="${OPTARG#*=}"
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
		Darwin)
			BOOTSTRAP_CFLAGS=" "
			BOOTSTRAP_LDFLAGS=" "
			CFLAGS=" "
			LDFLAGS=" "
			;;
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
if [ -n "$TARGET" ]; then
	[ -z "$TARGET_MACHINE" ] && TARGET_MACHINE="${TARGET##*-}"
	[ -z "$TARGET_SYSTEM" ] && TARGET_SYSTEM="${TARGET%-*}"
else
	[ -z "$TARGET_MACHINE" ] && TARGET_MACHINE="$MACHINE"
	[ -z "$TARGET_SYSTEM" ] && TARGET_SYSTEM="$SYSTEM"
	[ -z "$TARGET" ] && TARGET="$TARGET_SYSTEM-$TARGET_MACHINE"
fi

#initialize the target
[ -z "$OBJDIR" ] && OBJDIR="$PWD/objdir-$HOST"
[ -z "$TOOLDIR" ] && TOOLDIR="$PWD/tooldir-$HOST"

#check for bootstrap
[ -r "$OBJDIR/System/src/libSystem/libSystem-git/src/libSystem.a" ] \
	|| BOOTSTRAP="$BOOTSTRAP libsystem_static"
[ -x "$TOOLDIR/bin/configure$EXEEXT" ] \
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

#import the target
if [ ! -f "Apps/Devel/src/scripts/scripts-git/targets/$TARGET" ]; then
	_warning "$TARGET: Unsupported target" 1>&2
else
	. "Apps/Devel/src/scripts/scripts-git/targets/$TARGET"
fi

#initialize variables
[ -z "$PREFIX" ] && PREFIX="/usr/local"
[ -z "$CONFIGURE" ] && CONFIGURE="$TOOLDIR/bin/configure$EXEEXT -O \"$TARGET_SYSTEM\" -p \"$PREFIX\""
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
			("target_$target")
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
