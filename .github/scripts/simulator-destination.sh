#!/usr/bin/env bash
# Prints an xcodebuild destination for the newest available iPhone simulator,
# so the workflow doesn't depend on the device names of a specific runner image.
set -euo pipefail

udid=$(xcrun simctl list devices available --json | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
def version(runtime):
    return [int(n) for n in re.findall(r"\d+", runtime)]
for runtime in sorted((r for r in devices if ".iOS-" in r), key=version, reverse=True):
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
sys.exit("No available iPhone simulator found")
')

echo "platform=iOS Simulator,id=${udid}"
