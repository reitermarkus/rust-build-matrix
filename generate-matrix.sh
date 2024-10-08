#!/usr/bin/env bash

set -euo pipefail

rustup toolchain install nightly

if ! targets="$(cargo +nightly -Z unstable-options config get build.target --format json 2>/dev/null | jq .build.target)"; then
  targets='["x86_64-unknown-linux-gnu", "x86_64-apple-darwin", "aarch64-apple-darwin"]'
fi

# Ensure a single target is an array.
if [[ "${targets}" = \"*\" ]]; then
  targets="[${targets}]"
fi

toolchain="$(rustup show active-toolchain | sed -E 's/-x86_64.*//')"

if ! feature_matrix="$(cargo metadata --no-deps --format-version 1 | jq '.packages[0].metadata["feature-matrix"] // [[]]')"; then
  feature_matrix='[[]]'
fi

matrix="$(
  jq -c \
    --arg toolchain "${toolchain}" \
    --argjson feature_matrix "${feature_matrix}" \
    'map(
      {
        "os": (if (. | test(".*darwin.*")) then "macos-latest" else "ubuntu-latest" end),
        "toolchain": $toolchain,
        "target": .,
      } | .["use-cross"] = (.os == "ubuntu-latest")
    ) as $matrix |
    $feature_matrix | map(. as $features | $matrix | map(.features = $features) | .[])' <<< "${targets}"
)"

jq -C <<< "${matrix}"
echo "matrix=${matrix}" >> "${GITHUB_OUTPUT}"
