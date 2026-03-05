#!/bin/sh
#
# Returns the version of the running CoreDNS binary.
# Parses the output of `coredns --version`.
# Returns non-zero if the version cannot be determined.

VERSION=$(coredns --version 2>&1 | grep -oE 'CoreDNS-[0-9]+\.[0-9]+\.[0-9]+' | sed 's/CoreDNS-//')

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "Failed to determine CoreDNS version" >&2
  exit 1
fi

printf '%s\n' "$VERSION"
