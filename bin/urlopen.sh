#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-06 18:59:32 +0100 (Tue, 06 Oct 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Opens the URL given as an arg, or first URL from standard input or a given file

Used by .vimrc to instantly open a URL on the given line in the editor

Very useful for quickly referencing inline documentation links found throughout my GitHub repos
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<url_or_file_with_url>]"

help_usage "$@"

max_args 1 "$@"

browse(){
    local url="$1"
    if is_mac; then
        open "$url"
    else  # assume Linux
        if type -P xdg-open &>/dev/null; then
            xdg-open "$url" &
        elif type -P gnome-open &>/dev/null; then
            gnome-open "$url" &
        else
            die "ERROR: xdg-open and gnome-open not found"
        fi
    fi
}

"$srcdir/urlextract.sh" "$@" |
# head -n1 because grep -m 1 can't be trusted and sometimes outputs more matches on subsequent lines
head -n1 |
while read -r url; do
    browse "$url"
done
