#!/bin/sh -e
#$Id$
#Copyright (c) 2012-2026 Pierre Pronchery <khorben@defora.org>
#This file is part of the DeforaOS Project.
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
CONFIGSH="./config.sh"
DESTDIR="$PWD/destdir"
GIT_BRANCH='master'
PREFIX="/usr/local"
LIBDIR="$PREFIX/lib"
PROJECTCONF="project.conf"
PROGNAME="script.sh"
TARGZEXT=".tar.gz"
URL=
VERBOSE=1
#executables
BOMTOOL="bomtool"
[ -z "$CONFIGURE" ] && CONFIGURE='configure -v'
DEBUG="_debug"
FETCH='wget'
GIT='git'
INSTALL="install"
[ -n "$MAKE" ] || MAKE='make'
MKDIR="mkdir -p"
PATCH="patch"
RM='rm -f'
TAR='tar'
TOUCH='touch'
TR="tr"


#functions
#config_get
_config_get()
{
	filename="$1"
	section="$2"
	variable="$3"
	cursection=
	value=

	while read line; do
		case "$line" in
			"#"*)
				#ignore comments
				;;
			"["*"]")
				cursection="${line#[}"
				cursection="${cursection%]}"
				;;
			*"="*)
				curvariable="${line%%=*}"
				curvalue="${line#*=}"
				[ "$cursection" != "$section" \
					-o "$curvariable" != "$variable" ] ||
					value="$curvalue"
				;;
		esac
	done < "$filename"
	ret=$?
	[ $ret -eq 0 ] || return $ret
	echo "$value"
}


#debug
_debug()
{
	[ $VERBOSE -lt 3 ] || echo "$@" 1>&2
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
	[ $VERBOSE -lt 2 ] || echo "$PROGNAME: $@"
}


#target_configure
_target_configure()
{
	if [ -f "$PACKAGE-$VERSION/autogen.sh" ]; then
		(cd "$PACKAGE-$VERSION" && $DEBUG ./autogen.sh)
	fi
	if [ -f "$PACKAGE-$VERSION/configure" ]; then
		(cd "$PACKAGE-$VERSION" && $DEBUG ./configure)
	elif [ -f "$PACKAGE-$VERSION/$PROJECTCONF" ]; then
		(cd "$PACKAGE-$VERSION" && $DEBUG $CONFIGURE -p "$PREFIX")
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
		all|install|tests|uninstall)
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
		configure|download|extract|package|patch|sbom)
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
		sbom)
			_target_sbom
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
				_warning "$URL: Repository access is not encrypted"
				$DEBUG $GIT clone -n "$URL" "$PACKAGE-$VERSION"
			fi
			;;
		https://*.git|*.git)
			if [ ! -d "$PACKAGE-$VERSION/.git" ]; then
				$DEBUG $GIT clone -n "$URL" "$PACKAGE-$VERSION"
			fi
			;;
		ftps://*|https://*)
			[ -f "$PACKAGE-$VERSION$TARGZEXT" ] || $DEBUG $FETCH "$URL"
			;;
		ftp://*|http://*)
			if [ ! -f "$PACKAGE-$VERSION$TARGZEXT" ]; then
				_warning "$URL: Repository access is not encrypted"
				$DEBUG $FETCH "$URL"
			fi
			;;
	esac
}


#target_extract
_target_extract()
{
	case "$VERSION" in
		"git")
			(cd "$PACKAGE-$VERSION" &&
				$DEBUG $GIT checkout "$GIT_BRANCH" &&
				if [ -f ".gitmodules" ]; then
					$DEBUG $GIT submodule init &&
						$DEBUG $GIT submodule update
				fi)
			;;
		*)
			[ -d "$PACKAGE-$VERSION" ] || $DEBUG $TAR -xzf "$PACKAGE-$VERSION$TARGZEXT"
			;;
	esac
}


#target_make
_target_make()
{
	(cd "$PACKAGE-$VERSION" && $DEBUG $MAKE "$@")
}


#target_package
_target_package()
{
	$RM -r "$DESTDIR"
	_target_make DESTDIR="$DESTDIR" 'install' &&
	(cd "$DESTDIR" && $DEBUG $TAR -czf - "${PREFIX##/}") \
		> "$PWD/$PACKAGE-$VERSION.pkg"
}


#target_patch
_target_patch()
{
	filename="patch-${PACKAGE}_$VERSION.diff"

	[ ! -f "$PACKAGE-$VERSION/.patch-done" ]		|| return 0
	if [ -f "$filename" ]; then
		(cd "$PACKAGE-$VERSION" && $DEBUG $PATCH -p1 < "../$filename") &&
			$DEBUG $TOUCH "$PACKAGE-$VERSION/.patch-done"
	fi
}


#target_sbom
_target_sbom()
{
	sbomdir="$LIBDIR/sbom"
	spdxdir="$sbomdir/SPDX-2.2"
	name="$PACKAGE"
	[ -n "$VENDOR" ] && name="$VENDOR-$name"
	name=$(echo "$name" | $TR A-Z a-z)
	version="$VERSION"

	#clean
	if [ $clean -ne 0 ]; then
		$DEBUG $RM -- "$OBJDIR$name.pc" "$OBJDIR$name.spdx"
		return $?
	fi

	#uninstall
	if [ $uninstall -ne 0 ]; then
		$DEBUG $RM -- "$DESTDIR$sbomdir/$name.pc"
		$DEBUG $RM -- "$DESTDIR$spdxdir/$name.spdx"
		return $?
	fi

	#version
	if [ "$version" = "git" -a -f "$PACKAGE-$VERSION/$PROJECTCONF" ]; then
		v=$(_config_get "$PACKAGE-$VERSION/$PROJECTCONF" "" "version")
		[ -n "$v" ] && version="$v+git"
	fi

	#license
	license=$(_config_get "$PROJECTCONF" "metadata" "license")
	[ -n "$license" ] || license="NOASSERTION"

	#generate the pkgconfig file
	[ -n "$OBJDIR" ] && $DEBUG $MKDIR -- "$OBJDIR"
	(_sbom_field "Name" "$name"
	_sbom_field "Description" "$(_config_get "$PROJECTCONF" "metadata" "description")"
	_sbom_field "Version" "$version"
	_sbom_field "Copyright" "$(_config_get "$PROJECTCONF" "metadata" "copyright")"
	_sbom_field "URL" "$(_config_get "$PROJECTCONF" "metadata" "homepage")"
	_sbom_field "Source" "$(_config_get "$PROJECTCONF" "metadata" "download")"
	_sbom_field "License" "$license"
	_sbom_field "Maintainer" "$(_config_get "$PROJECTCONF" "metadata" "maintainer")"
	_sbom_field "Requires" "$(_config_get "$PROJECTCONF" "metadata" "depends")") > "$OBJDIR$name.pc"
	res=$?
	[ $res -eq 0 ] || return $res

	#generate the SPDX file
	PKG_CONFIG_PATH="$PWD:$DESTDIR$sbomdir" $DEBUG $BOMTOOL "$name" > "$OBJDIR$name.spdx"
	res=$?
	[ $res -eq 0 ] || return $res

	[ $install -eq 0 ] && return 0

	$DEBUG $MKDIR -- "$DESTDIR$spdxdir" &&
		$DEBUG $INSTALL -m 0644 "$OBJDIR$name.pc" "$DESTDIR$sbomdir/$name.pc" &&
		$DEBUG $INSTALL -m 0644 "$OBJDIR$name.spdx" "$DESTDIR$spdxdir/$name.spdx"
}

_sbom_field()
{
	key="$1"
	value="$2"

	[ -z "$value" ] || echo "$key: $value"
}


#target_tests
_target_tests()
{
	(cd "$PACKAGE-$VERSION" && $DEBUG $MAKE "$@")
}


#usage
_usage()
{
	echo "Usage: $PROGNAME [-c|-i|-u][-O name=value...][-P prefix][-qv] target..." 1>&2
	echo "  -c	Perform the \"clean\" target" 1>&2
	echo "  -i	Perform the \"install\" target" 1>&2
	echo "  -q	Run in quiet mode" 1>&2
	echo "  -u	Perform the \"uninstall\" target" 1>&2
	echo "  -v	Run in verbose mode" 1>&2
	echo "Available targets:" 1>&2
	echo "  build" 1>&2
	echo "  configure" 1>&2
	echo "  download" 1>&2
	echo "  extract" 1>&2
	echo "  install" 1>&2
	echo "  package" 1>&2
	echo "  patch" 1>&2
	echo "  sbom" 1>&2
	echo "  tests" 1>&2
	echo "  uninstall" 1>&2
	return 1
}


#warning
_warning()
{
	echo "$PROGNAME: warning: $@" 1>&2
}


#main
if [ ! -f "$CONFIGSH" ]; then
	_error "Must be called from a project folder ($CONFIGSH not found)"
	exit $?
fi
. "$CONFIGSH"

clean=0
install=0
uninstall=0
while getopts "ciO:P:quv" name; do
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
			LIBDIR="$PREFIX/lib"
			;;
		q)
			VERBOSE=0
			;;
		u)
			uninstall=1
			;;
		v)
			VERBOSE=$((VERBOSE + 1))
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
