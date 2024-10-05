#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob

gist_url=https://gist.githubusercontent.com/mtth/79f9e30413a4cb8b1a9fc3fe66cdf5e5

usage() { # [CODE]
	local cmd="${0##*/}"
	cat <<-EOF
		Install dotfiles

		See $gist_url
		for more information.

		Usage:
		  $cmd [-hmsd PATH]

		Options:
		  -d PATH  Directory path used to store .files/. Defaults to \$HOME.
		  -h       Show help and exit.
		  -m       Manual mode, do not invoke the installation script.
		  -s       Skip GPG key import.

		Examples:
		  bash <(curl -s https://mtth.github.io/x/dotfiles.sh)
	EOF
	exit "${1:-2}"
}

main() {
	local opt workdir="$HOME" import_key=1 run_install=1
	while getopts :d:hms opt "$@"; do
		case "$opt" in
			d) workdir="$OPTARG" ;;
			m) run_install=0 ;;
			s) import_key=0 ;;
			h) usage 0 ;;
			*) printf 'unknown option: %s\n' "$OPTARG" >&2 && usage ;;
		esac
	done
	shift $(( OPTIND-1 ))

	if (( import_key )); then
		gpg --keyserver hkps://keys.openpgp.org --recv-keys 5AA4C330351F0BCD
	fi

	cd "$workdir"
	curl "$gist_url/raw/dotfiles.tar.gz.asc" \
		| gpg --decrypt | tar --extract --gunzip
	if (( PIPESTATUS[1] == 0 )); then
		printf 'dotfiles imported to %s\n' "$workdir/.files"
		if (( run_install )); then
			.files/install.sh
		fi
	else
		echo 'Invalid signature'
	fi
}

main "$@"
