#!/usr/bin/env bash
# Copyright 2009 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e
. ./env.bash

export MAKEFLAGS=-j4
unset CDPATH	# in case user has it set

rm -f "$GOBIN"/quietgcc
CC=${CC:-gcc}
sed -e "s|@CC@|$CC|" < "$GOROOT"/src/quietgcc.bash > "$GOBIN"/quietgcc
chmod +x "$GOBIN"/quietgcc

rm -f "$GOBIN"/gomake
MAKE=make
if ! make --version 2>/dev/null | grep 'GNU Make' >/dev/null; then
	MAKE=gmake
fi
(echo '#!/bin/sh'; echo 'exec '$MAKE' "$@"') >"$GOBIN"/gomake
chmod +x "$GOBIN"/gomake

if [ -d /selinux -a -f /selinux/booleans/allow_execstack ] ; then
	if ! cat /selinux/booleans/allow_execstack | grep -c '^1 1$' >> /dev/null ; then
		echo "WARNING: the default SELinux policy on, at least, Fedora 12 breaks "
		echo "Go. You can enable the features that Go needs via the following "
		echo "command (as root):"
		echo "  # setsebool -P allow_execstack 1"
		echo
		echo "Note that this affects your system globally! "
		echo
		echo "The build will continue in five seconds in case we "
		echo "misdiagnosed the issue..."

		sleep 5
	fi
fi

(
	cd "$GOROOT"/src/pkg;
	bash deps.bash	# do this here so clean.bash will work in the pkg directory
)
bash "$GOROOT"/src/clean.bash

for i in lib9 libbio libmach cmd pkg libcgo cmd/cgo cmd/ebnflint cmd/godoc cmd/gofmt cmd/goinstall cmd/goyacc cmd/hgpatch
do
	case "$i-$GOOS-$GOARCH" in
	libcgo-nacl-* | cmd/*-nacl-* | libcgo-linux-arm)
		;;
	*)
		# The ( ) here are to preserve the current directory
		# for the next round despite the cd $i below.
		# set -e does not apply to ( ) so we must explicitly
		# test the exit status.
		(
			echo; echo; echo %%%% making $i %%%%; echo
			cd "$GOROOT"/src/$i
			case $i in
			cmd)
				bash make.bash
				;;
			pkg)
				"$GOBIN"/gomake install
				;;
			*)
				"$GOBIN"/gomake install
			esac
		)  || exit 1
	esac
done

case "`uname`" in
Darwin)
	echo;
	echo %%% run sudo.bash to install debuggers
	echo
esac
