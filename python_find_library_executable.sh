#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-15 09:59:01 +0100 (Sun, 15 Sep 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Returns the first argument that is found as an executable in the $PATH, with preference given to local Python library installation
#
# Useful for Macs to find where libraries executable scripts like nosetests are, which may get installed locally in $HOME/Library/Python/2.7/bin to avoid Mac OS X System Integrity Protection

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

# finds weird things like this to make $PATH work:
#
# /usr/local/Cellar/numpy/1.14.5/libexec/nose/bin
#
# Since nose is available in brew Cellar's numpy, it doesn't get installed to ~/Library and isn't found otherwise.
# Rather than do an --ignore-installed which could cause all sorts of other issues, just use it from wherever it is found
while read -r path; do
    bin="${path%/lib/python*/site-packages*}/bin"
    if [ -d "$bin" ]; then
        export PATH="$bin:$PATH"
    fi
done < <(python -c 'from __future__ import print_function; import sys; print("\n".join(reversed(sys.path)))' | sed '/^[[:space:]]*$/d')

for path in ~/Library/Python/*; do
    bin="$path/bin"
    [ -d "$bin" ] || continue
    export PATH="$bin:$PATH"
done

# prioritise our default python at the beginning of the $PATH
python_version="$(python -c 'from __future__ import print_function; import sys; print("{}.{}".format(sys.version_info.major, sys.version_info.minor))')"
bin=~/Library/Python/"$python_version"/bin

if [ -d "$bin" ]; then
    export PATH="$bin:$PATH"
fi

set +o pipefail
found="$(which "$@" | head -n 1)"
set -o pipefail

if [ -n "$found" ]; then
    echo "$found"
else
    echo "no Python executable was found matching any of: $*" >&2
    echo "\$PATH searched was: $PATH" >&2
    exit 1
fi
