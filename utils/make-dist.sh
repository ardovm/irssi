#!/bin/sh
# Run this to create a distribution tarball from a git checkout

set -e

PKG_NAME="Irssi"

repo_root="$(git rev-parse --show-toplevel)"
dist_tmp="$repo_root/${PKG_NAME}-Dist"

if [ -z "$repo_root" ]; then
    echo "**Error**: ${PKG_NAME} make-dist.sh must be run in a git clone, cannot proceed."
    exit 1
fi

if [ ! -f "$repo_root"/irssi.conf ]; then
    echo -n "**Error**: Directory \`$repo_root' does not look like the"
    echo " top-level $PKG_NAME directory"
    exit 1
fi

cd "$repo_root"
./utils/check-perl-hash.sh

rm -fr "$dist_tmp"
git clone --no-local "$repo_root" "$dist_tmp"
cd "$dist_tmp"
if [ ! -f meson.build ]; then
    echo "**Error**: ${PKG_NAME} make-dist.sh could not find meson.build, cannot proceed."
    exit 1
fi

name=$(perl -0777 -n -e "m{project\\(\\s*'(.*?)'}s and print \$1 and exit" meson.build)
version=$(perl -0777 -n -e "m{project\\(.*?,\\s*version\\s*:\\s*'(.*?)'}s and print \$1 and exit" meson.build)
if [ -z "$name" ] || [ -z "$version" ]; then
    echo "**Error**: ${PKG_NAME} make-dist.sh could not find either name or version, cannot proceed."
    exit 1
fi

cat <<SETUP_CFG >setup.cfg
[metadata]
name = $name
version = $version
url = https://ailin-nemui.github.io/irssi/
maintainer = Ailin Nemui
license = GNU General Public License v2 or later (GPLv2+)

SETUP_CFG
python3 -c 'from setuptools import *;setup()' sdist --formats=tar

tar --delete --file "dist/$name-$version.tar" \
    "$name-$version/setup.cfg" \
    "$name-$version/$name.egg-info" \
    "$name-$version/PKG-INFO"

xz -k "dist/$name-$version.tar"
gzip -k "dist/$name-$version.tar"

mv -v dist/*.tar.* "$repo_root"
cd "$repo_root"
# rm -fr "$dist_tmp"