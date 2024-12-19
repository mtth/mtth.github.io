#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob

gist_url=https://gist.githubusercontent.com/mtth/79f9e30413a4cb8b1a9fc3fe66cdf5e5
gpg_fingerprint=5AA4C330351F0BCD

default_pager=less

usage() {
	local name="${0##*/}"
	cat <<-EOF
		Install dotfiles

		See $gist_url
		for more information.

		Synopsis:
		  $name [-Imsd PATH]
		  $name -V [-s] PATTERN
		  $name -h

		Commands:
		  -I          Install the dotfiles, linking all user resources. This is the
		              default command.
		  -V PATTERN  View the files matching PATTERN within the .files/ folder.
		  -h          Show help and exit.

		Options:
		  -d PATH   Directory path used to store .files/. Defaults to \$HOME.
		  -m        Manual mode, do not invoke the installation script.
		  -p PAGER  Pager to use for viewing files. Defaults to $default_pager.
		  -s        Skip GPG key import.

		Examples:
		  bash <(curl -s https://mtth.github.io/x/dotfiles.sh)
	EOF
	exit "${1:-2}"
}

main() {
	local \
		cmd=INSTALL \
		import_key=1 pager="$default_pager" run_install=1 workdir="$HOME" \
		opt
	while getopts :IVd:hmp:s opt "$@"; do
		case "$opt" in
			I) cmd=INSTALL ;;
			V) cmd=VIEW ;;
			d) workdir="$OPTARG" ;;
			h) usage 0 ;;
			m) run_install=0 ;;
			p) pager="$OPTARG" ;;
			s) import_key=0 ;;
			*) fail "unknown option: $OPTARG" ;;
		esac
	done
	shift $(( OPTIND-1 ))

	if (( import_key )); then
		gpg --keyserver hkps://keys.openpgp.org --recv-keys "$gpg_fingerprint"
	fi

	case "$cmd" in
		INSTALL)
			(( $# == 0 )) || fail 'expected 0 arguments'
			install
			;;
		VIEW)
			(( $# == 1 )) || fail 'expected 1 argument'
			view "$1"
			;;
		*) fail 'unexpected command' ;;
	esac
}

fail() { # MSG
	printf 'error: %s\n' "$1" >&2 && exit 1
}

install() {
	cd "$workdir"

	curl -s "$gist_url/raw/dotfiles.tar.gz.asc" \
		| gpg --decrypt | tar --extract --gunzip
	(( PIPESTATUS[1] == 0 )) || fail 'Invalid signature'
	printf 'dotfiles imported to %s\n' "$workdir/.files"

	if (( run_install )); then
		.files/install.sh
	fi
}

view() { # PATTERN
	local pattern="$1" tmpdir
	tmpdir="$(mktemp -d --tmpdir dotfiles.XXXXX)"
	trap "rm -rf '$tmpdir'" EXIT
	cd "$tmpdir"

	curl -s "$gist_url/raw/dotfiles.tar.gz.asc" | gpg -q --decrypt >files.tar.gz
	tar -tzf files.tar.gz | grep -E "$pattern" | grep -Ev '/$' >names.txt \
		|| fail 'no matching files'
	tar -xzf files.tar.gz -T names.txt
	find .files -type f -print0 | xargs -0 "$pager"
}

main "$@"
