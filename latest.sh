#!/bin/sh
#
# Fetches the latest stable CoreDNS release version from GitHub.
# Strips the leading 'v' prefix and any whitespace.
# Returns non-zero if the API call fails or returns no tag.

LATEST=$(curl -sL "https://api.github.com/repos/coredns/coredns/releases/latest" \
         | jq -r '.tag_name' \
         | sed 's/^v//' \
         | tr -d '[:space:]')

if [ -z "$LATEST" ] || [ "$LATEST" = "null" ]; then
  echo "Failed to retrieve latest CoreDNS release version" >&2
  exit 1
fi

printf '%s\n' "$LATEST"
