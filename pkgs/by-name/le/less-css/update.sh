#!/usr/bin/env nix-shell
#!nix-shell -i bash -p ripgrep common-updater-scripts nodejs prefetch-npm-deps

set -xeu -o pipefail

PACKAGE_DIR="$(realpath "$(dirname "$0")")"
cd "$PACKAGE_DIR/.."
while ! test -f flake.nix; do cd .. ; done
NIXPKGS_DIR="$PWD"

version="$(
  list-git-tags --url=https://github.com/less/less.js \
  | rg '^v([\d.]+)$' -r '$1' \
  | sort --version-sort \
  | tail -n1
)"
update-source-version less-css "$version"

TMPDIR="$(mktemp -d)"
trap "rm -rf '$TMPDIR'" EXIT
cd "$TMPDIR"

src="$(nix-build --no-link "$NIXPKGS_DIR" -A less-css.src)"
cp $src/packages/less/package*.json .

test -f package-lock.json || npm install --package-lock-only

npmDepsHash=$(prefetch-npm-deps ./package-lock.json)
sed -E "s@npmDepsHash = \".*?\"@npmDepsHash = \"$npmDepsHash\"@" -i "$PACKAGE_DIR/package.nix"
