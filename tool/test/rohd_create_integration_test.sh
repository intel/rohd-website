#!/usr/bin/env bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

readonly WEBSITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT
readonly BUNDLE_DIRECTORY="$FIXTURE/bundles"
readonly LAUNCHER_DIRECTORY="$FIXTURE/launcher"
readonly DESTINATION="$FIXTURE/test"

python3 "$WEBSITE_ROOT/tool/build_rohd_create_bundles.py" "$BUNDLE_DIRECTORY"
unzip -q "$BUNDLE_DIRECTORY/rohd_create_linux.zip" -d "$LAUNCHER_DIRECTORY"
bash "$LAUNCHER_DIRECTORY/rohd_create/rohd_create.sh" "$DESTINATION" \
  --package-name my_first_module \
  --module-name MyFirstModule

(
  cd "$DESTINATION"
  dart analyze
  dart test
)

echo 'ROHD Create generated package checks passed.'
