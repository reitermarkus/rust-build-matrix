#!/usr/bin/env bash

set -euo pipefail

set -x

if ! targets="$(cargo +nightly -Z unstable-options config get build.target --format json 2>/dev/null | jq .build.target)"; then
  targets='["x86_64-unknown-linux-gnu", "x86_64-apple-darwin", "aarch64-apple-darwin"]'
fi

toolchain="$(rustup show active-toolchain | sed -E 's/-x86_64.*//')"

matrix="$(
  jq -c \
    --arg toolchain "${toolchain}" \
    'map(
      {
        "os": (if (. | test(".*darwin.*")) then "macos-latest" else "ubuntu-latest" end),
        "toolchain": $toolchain,
        "target": .,
      } | .["use-cross"] = (.os == "ubuntu-latest")
    )' <<< "${targets}"
)"

jq -C <<< "${matrix}"
echo "matrix=${matrix}" >> "${GITHUB_OUTPUT}"
