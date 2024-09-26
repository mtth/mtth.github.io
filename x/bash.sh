#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob

gist_url=https://gist.githubusercontent.com/mtth/c88bdd26a0c4972e1c4355b21767751e

usage() { # [CODE]
	local cmd="${0##*/}"
	cat <<-EOF
		Launch customized Bash shell

		This scripts starts a Bash shell with a custom prompt and various helpers.
		See $gist_url
		for more information.

		Usage:
		  $cmd [-hs]

		Options:
		  -h  Show help and exit.
		  -s  Skip GPG key import.
	EOF
	exit "${1:-2}"
}

main() {
	local opt import_key=1
	while getopts :hs opt "$@"; do
		case "$opt" in
			s) import_key=0 ;;
			h) usage 0 ;;
			*) printf 'unknown option: %s\n' "$OPTARG" >&2 && usage ;;
		esac
	done
	shift $(( OPTIND-1 ))

	if (( import_key )); then
		gpg --keyserver hkps://keys.openpgp.org --recv-keys 5AA4C330351F0BCD
	fi

	local tmpdir
	tmpdir="$(mktemp -d --tmpdir bash.XXXX)"
	# shellcheck disable=SC2064
	trap "rm -rf -- '$tmpdir'" EXIT

	cd "$tmpdir"
	curl "$gist_url/raw/bash.tar.gz.asc" | gpg --decrypt | tar --extract --gunzip
	if (( PIPESTATUS[1] == 0 )); then
		echo 'Entering shell...'
		bash --rcfile src/login.sh -il
	else
		echo 'invalid signature'
	fi
}

main "$@"
