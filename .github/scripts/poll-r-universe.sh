#!/usr/bin/env bash
# Waits for r-universe to serve the new version, so a failed build there sends
# GitHub's failure email. Checks every 5 minutes, for up to 3 hours.
#
# Environment: VERSION.
set -euo pipefail

url="https://economic.r-universe.dev/api/packages/realtalk"
for attempt in $(seq 1 36); do
  served=$(curl -fsS "$url" | python3 -I -c 'import json, sys; print(json.load(sys.stdin).get("Version", ""))' || true)
  if [ "$served" = "$VERSION" ]; then
    echo "r-universe serves realtalk $VERSION."
    exit 0
  fi
  echo "Attempt $attempt: r-universe serves ${served:-nothing yet}; waiting for $VERSION."
  sleep 300
done
echo "::error::After 3 hours, r-universe still doesn't serve realtalk $VERSION. Check the build at https://github.com/r-universe/economic/actions."
exit 1
