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
		Dotfiles installation utility

		This script is useful to set up a temporary development environment. See
		$gist_url for
		more information.

		Synopsis:
		  $name -I [-kmd PATH]
		  $name -V [-kp PAGER] [PATTERN]
		  $name -h

		Commands:
		  -I  Install dotfiles.
		  -V  View the files matching PATTERN within the dotfiles/ folder. If
		      PATTERN is omitted, the list of file names is displayed.
		  -h  Show help and exit.

		Options:
		  -d PATH   Directory path used to store dotfiles/. Defaults to
		            \$HOME/.local/opt.
		  -k        Always import GPG key, even if it already exists.
		  -m        Manual mode, do not invoke the installation script.
		  -p PAGER  Pager to use for viewing files. Defaults to $default_pager.

		Examples:
		  bash <(curl -s https://mtth.github.io/x/dotfiles.sh) -I
	EOF
	exit "${1:-2}"
}

main() {
	local \
			cmd='' \
			OPT_import_key=0 pager="$default_pager" OPT_run_install=1 \
			OPT_workdir="$HOME/.local/opt" \
			opt
	while getopts :IVd:hkmp: opt "$@"; do
		case "$opt" in
			I) cmd=INSTALL ;;
			V) cmd=VIEW ;;
			d) OPT_workdir="$OPTARG" ;;
			h) usage 0 ;;
			k) OPT_import_key=1 ;;
			m) OPT_run_install=0 ;;
			p) pager="$OPTARG" ;;
			*) fail "unknown option: $OPTARG" ;;
		esac
	done
	shift $(( OPTIND-1 ))
	[[ -n $cmd ]] || usage 2

	ensure_key

	case "$cmd" in
		INSTALL)
			(( $# == 0 )) || fail 'expected 0 arguments'
			install
			;;
		VIEW)
			(( $# <= 1 )) || fail 'expected 0 or 1 arguments'
			view "${1:-}"
			;;
		*) fail 'unexpected command' ;;
	esac
}

fail() { # MSG
	printf 'error: %s\n' "$1" >&2 && exit 1
}

ensure_key() {
	if gpg -k "$gpg_fingerprint" &>/dev/null && (( ! OPT_import_key )); then
		return
	fi
	gpg --keyserver hkps://keys.openpgp.org --recv-keys "$gpg_fingerprint"
}

install() {
	mkdir -p "$OPT_workdir"
	cd "$OPT_workdir"

	curl -s "$gist_url/raw/dotfiles.tar.gz.asc" \
		| gpg --decrypt \
		| tar --extract --gunzip
	(( PIPESTATUS[1] == 0 )) || fail 'Invalid signature'
	printf 'dotfiles imported to %s\n' "$OPT_workdir/dotfiles"

	if (( OPT_run_install )); then
		dotfiles/install.sh
	fi
}

view() { # PATTERN
	local pattern="$1" tmpdir
	tmpdir="$(mktemp -d --tmpdir dotfiles.XXXXX)"
	trap "rm -rf '$tmpdir'" EXIT
	cd "$tmpdir"

	if ! curl -s "$gist_url/raw/dotfiles.tar.gz.asc" \
			| gpg -q --decrypt >dotfiles.tar.gz 2>errors.txt; then
		cat errors.txt
		fail 'invalid signature'
	fi

	if [[ -z $pattern ]]; then
		tar -tzf dotfiles.tar.gz | grep -Ev '/$'
	else
		tar -tzf dotfiles.tar.gz | grep -E "$pattern" | grep -Ev '/$' >names.txt \
			|| fail 'no matching files'
		tar -xzf dotfiles.tar.gz -T names.txt
		find dotfiles -type f -print0 | xargs -0 "$pager"
	fi
}

main "$@"
