#!/usr/bin/env bash
# Asks r-universe to sync now, then waits for it to serve the new version, so a
# failed build there sends GitHub's failure email. Checks every 5 minutes, for
# up to 3 hours.
#
# The sync request is best effort. The endpoint is undocumented (it's what the
# sync button on https://economic.r-universe.dev/packages calls) and takes no
# token. If it fails, r-universe's own scheduled sync still picks up the
# release, only later, so a failure warns and the wait goes on.
#
# Environment: VERSION.
set -euo pipefail

universe="https://economic.r-universe.dev"

# The response body is discarded so nothing r-universe sends reaches the log.
if curl -fsS --max-time 60 -X PATCH "$universe/api/sync" > /dev/null; then
  echo "Asked r-universe to sync."
else
  echo "::warning::Couldn't ask r-universe to sync. Waiting for its scheduled sync instead, which can take a few hours."
fi

url="$universe/api/packages/realtalk"
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
