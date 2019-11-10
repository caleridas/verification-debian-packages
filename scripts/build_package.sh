#!/bin/bash

set -e

function find_mirror() {
	local ORIGIN="$1"
	if [ ! -e "$GIT_MIRROR_REGISTRY" ] ; then
		echo "$ORIGIN"
		return
	fi

	while read -r repo mirror ; do
		if [[ "$repo" == "$ORIGIN" ]] ; then
			echo -n "$mirror"
			return
		fi
	done < "$GIT_MIRROR_REGISTRY"

	echo "$ORIGIN"
}

function make_tarball() {
	local ORIGIN="$1"
	local NAME="$2"
	local VERSION="$3"
	local TAG="$4"
	local DESTDIR="$5"

	git archive --prefix="$NAME"-"$VERSION"/ --format=tar --remote="$ORIGIN" "$TAG" | xz >"$DESTDIR""$NAME"_"$VERSION.orig.tar.xz"
}

function unpack_tarball() {
	local NAME="$1"
	local VERSION="$2"
	local DESTDIR="$3"

	(cd "$DESTDIR" ; tar xJf "$NAME"_"$VERSION.orig.tar.xz")
}

function prepare_build() {
	local NAME="$1"
	local VERSION="$2"
	local DESTDIR="$3"

	cp -a "$NAME"/debian "$DESTDIR"/"$NAME"-"$VERSION"/
}

function run_build() {
	local NAME="$1"
	local VERSION="$2"
	local DESTDIR="$3"
	(cd "$DESTDIR"/"$NAME"-"$VERSION" ; debuild)
}

NAME="$1"
source ./"$NAME"/meta-control
if [[ "$TAG" == "" ]] ; then
	TAG="$VERSION"
fi
BUILDDIR=/tmp/"$1"/

ORIGIN=$(find_mirror "$ORIGIN")

mkdir -p "$BUILDDIR"

echo "$NAME" "$ORIGIN" "$VERSION"

make_tarball "$ORIGIN" "$NAME" "$VERSION" "$TAG" "$BUILDDIR"
unpack_tarball "$NAME" "$VERSION" "$BUILDDIR"
prepare_build "$NAME" "$VERSION" "$BUILDDIR"
run_build "$NAME" "$VERSION" "$BUILDDIR"
