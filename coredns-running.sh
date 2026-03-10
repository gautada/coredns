#!/bin/sh
#
# Health check: verifies CoreDNS is responding to DNS queries.
# Uses the coredns health endpoint on port 8080.
# Returns 0 if CoreDNS is healthy, non-zero otherwise.

if curl -sf --max-time 5 http://localhost:8080/health > /dev/null 2>&1; then
 echo "coredns-running: CoreDNS health endpoint is responding"
 exit 0
fi

echo "coredns-running: CoreDNS health endpoint not responding on port 8080"
exit 1
