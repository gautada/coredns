#!/bin/sh
#
# Health check: verifies the running CoreDNS container version matches
# the latest image published to docker.io/gautada/coredns.
# Queries Docker Hub for the most recently updated non-'latest' tag
# and compares it to the running container version.
# Returns 0 if versions match, non-zero otherwise.
# Set FORCE_BYPASS=1 to suppress errors during intentional rolling updates.

if [ "${FORCE_BYPASS:-0}" = "1" ]; then
  echo "imgversion-check: FORCE_BYPASS set — skipping registry version check"
  exit 0
fi

CURRENT_VERSION=$(/usr/bin/container-version | tr -d '[:space:]')
if [ -z "$CURRENT_VERSION" ]; then
  echo "imgversion-check: failed to get running container version"
  exit 1
fi

# Query Docker Hub for the most recently pushed non-'latest' tag
REGISTRY_VERSION=$(curl -sL \
  "https://hub.docker.com/v2/repositories/gautada/coredns/tags/?page_size=25&ordering=last_updated" \
  | jq -r '[.results[] | select(.name != "latest")] | .[0].name' \
  | tr -d '[:space:]')

if [ -z "$REGISTRY_VERSION" ] || [ "$REGISTRY_VERSION" = "null" ]; then
  echo "imgversion-check: failed to fetch registry version from Docker Hub"
  exit 1
fi

echo "Running version:  $CURRENT_VERSION"
echo "Registry latest:  $REGISTRY_VERSION"

if [ "$CURRENT_VERSION" = "$REGISTRY_VERSION" ]; then
  echo "imgversion-check: running image matches registry latest"
  exit 0
fi

echo "imgversion-check: version mismatch — running $CURRENT_VERSION, registry latest $REGISTRY_VERSION"
exit 1
