#!/usr/bin/env bash
# Prints an xcodebuild destination for the newest available simulator of a device family
# (iPhone by default, or iPad), so the workflow doesn't depend on the device names of a
# specific runner image.
#
# Usage: simulator-destination.sh [iPhone|iPad]
set -euo pipefail

family="${1:-iPhone}"

udid=$(xcrun simctl list devices available --json | FAMILY="$family" python3 -c '
import json, os, re, sys
family = os.environ["FAMILY"]
devices = json.load(sys.stdin)["devices"]
def version(runtime):
    return [int(n) for n in re.findall(r"\d+", runtime)]
for runtime in sorted((r for r in devices if ".iOS-" in r), key=version, reverse=True):
    for device in devices[runtime]:
        if device["name"].startswith(family):
            print(device["udid"])
            sys.exit(0)
sys.exit("No available " + family + " simulator found")
')

echo "platform=iOS Simulator,id=${udid}"
