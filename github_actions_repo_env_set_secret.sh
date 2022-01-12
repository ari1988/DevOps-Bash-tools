#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: harisekhon/devops-bash-tools testenv haritest=stuff haritest2=stuff2
#
#  Author: Hari Sekhon
#  Date: 2021-12-03 17:41:23 +0000 (Fri, 03 Dec 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/ee/api/project_level_variables.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds / updates GitHub repo environment-level secrets from args or stdin, for use in GitHub Actions

If no third argument is given, reads environment variables from standard input, one per line in 'key=value' format or 'export key=value' shell format

Examples:

    ${0##*/} github/HariSekhon/DevOps-Bash-tools testenv AWS_ACCESS_KEY_ID=AKIA...

    echo AWS_ACCESS_KEY_ID=AKIA... | ${0##*/} HariSekhon/DevOps-Bash-tools testenv


    Loads both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY via stdin:

        aws_csv_creds.sh credentials_exported.csv | ${0##*/} HariSekhon/DevOps-Bash-tools testenv


Requires the GitHub CLI 'gh' to be installed and available in the \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner_repo_or_id> <environment_name> [<key>=<value> <key2>=<value2> ...]"

help_usage "$@"

# requires the GitHub CLI
check_bin gh

min_args 2 "$@"

owner_repo="$1"
environment_name="$2"
shift || :
shift || :

if ! [[ "$owner_repo" =~ ^[[:alnum:]-]+/[[:alnum:]-]+$ ]]; then
    usage "owner_repo given '$owner_repo' does not conform <user_or_org>/<repo> format"
fi

# don't need to check for existing secrets as the API is a set (add/update) operation anyway
#existing_secrets="$("$srcdir/github_api.sh" "/repos/$owner_repo/tonkasim/actions/secrets" | jq -r '.secrets[].name')"

# needed to create an encrypted value against the repo's public key before upload
#repo_public_key_data="$("$srcdir/github_api.sh" "/repos/$owner_repo/actions/secrets/public-key")"
#repo_public_key="$(jq -r '.key' <<< "$repo_public_key_data")"
#repo_public_key_id="$(jq -r '.key_id' <<< "$repo_public_key_data")"

add_secret(){
    local env_var="$1"
    parse_export_key_value "$env_var"
    value="$(base64 <<< "$value")"
    # shellcheck disable=SC2154
    timestamp "setting GitHub secret '$key' in repo '$owner_repo' environment '$environment_name'"
    # XXX: no way to generate this encrypted value in Bash at this time, all language bindings but no Libsodium CLI so use GitHub CLI instead
    # https://docs.github.com/en/rest/reference/actions#create-or-update-an-environment-secret
    command gh secret set -R "$owner_repo" --env "$environment_name" "$key" <<< "$value"
}


if [ $# -gt 0 ]; then
    for arg in "$@"; do
        add_secret "$arg"
    done
else
    while read -r line; do
        add_secret "$line"
    done
fi
