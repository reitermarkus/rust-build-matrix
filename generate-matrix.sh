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

package_metadata="$(cargo metadata --no-deps --format-version 1)"
package_name="$(jq -r '(.packages | sort_by(.publish == []) | sort_by(.name) | first | .name)' <<< "${package_metadata}")"
has_cargo_feature_combinations="$(jq -r --arg package_name $package_name '.packages[] | select(.name == $package_name) | .metadata | (has("cargo-fc") or has("fc") or has("cargo-feature-combinations") or has("feature-combinations"))' <<< "${package_metadata}")"

matrix="$(
  jq -c \
    --arg toolchain "${toolchain}" \
    --argjson has_cargo_feature_combinations "${has_cargo_feature_combinations}" \
    '. | map(
      {
        "os": (if (. | test(".*darwin.*")) then "macos-latest" elif (. | test(".*windows.*")) then "windows-latest" else "ubuntu-latest" end),
        "toolchain": $toolchain,
        "target": .,
        "use-cargo-feature-combinations": $has_cargo_feature_combinations,
      } |
      .["use-cross"] = (.os == "ubuntu-latest" and .target != "x86_64-unknown-linux-gnu")
    )' <<< "${targets}"
)"

jq -C <<< "${matrix}"
echo "matrix=${matrix}" >> "${GITHUB_OUTPUT}"
