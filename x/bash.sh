#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob

gist_url=https://gist.githubusercontent.com/mtth/c88bdd26a0c4972e1c4355b21767751e
gpg_fingerprint=5AA4C330351F0BCD

usage() {
	local cmd="${0##*/}"
	cat <<-EOF
		Launch customized Bash shell

		This scripts starts a Bash shell with a custom prompt and various helpers.
		See $gist_url
		for more information.

		Synopsis:
		  $cmd -S [-k]
		  $cmd -h

		Commands:
		  -S  Start shell.
		  -h  Show help and exit.

		Options:
		  -k  Always import GPG key, even if it already exists.

		Examples:
		  bash <(curl -s https://mtth.github.io/x/bash.sh) -S
	EOF
	exit "${1:-2}"
}

main() {
	local cmd='' import_key=0 opt
	while getopts :Shk opt "$@"; do
		case "$opt" in
			S) cmd=start ;;
			h) usage 0 ;;
			k) import_key=1 ;;
			*) fail "unknown option: $OPTARG" ;;
		esac
	done
	shift $(( OPTIND-1 ))
	[[ -n $cmd ]] || usage 2

	ensure_key

	local tmpdir
	tmpdir="$(mktemp -d --tmpdir bash.XXXX)"
	# shellcheck disable=SC2064
	trap "rm -rf -- '$tmpdir'" EXIT

	cd "$tmpdir"
	curl "$gist_url/raw/bash.tar.gz.asc" | gpg --decrypt | tar --extract --gunzip
	if (( PIPESTATUS[1] == 0 )); then
		echo 'Entering shell...'
		bash --rcfile src/login.sh
	else
		fail 'Invalid signature'
	fi
}

fail() { # MSG
	printf 'error: %s\n' "$1" >&2 && exit 1
}

ensure_key() {
	if gpg -k "$gpg_fingerprint" &>/dev/null && (( ! import_key )); then
		return
	fi
	gpg --keyserver hkps://keys.openpgp.org --recv-keys "$gpg_fingerprint"
}

main "$@"
