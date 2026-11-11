#!/usr/bin/env bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#
# build_rohd_create_bundles_test.sh
# Tests ROHD Create platform bundle contents and Linux extraction behavior.
#
# 2026 October 25
# Author: Desmond A. Kirkpatrick <desmond.a.kirkpatrick@intel.com>

set -euo pipefail

readonly WEBSITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly BUILDER="$WEBSITE_ROOT/tool/build_rohd_create_bundles.py"
readonly FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT
readonly DOWNLOADS="$FIXTURE/downloads"
readonly EXTRACTED="$FIXTURE/extracted"
readonly DESTINATION="$FIXTURE/my-first-module"

python3 "$BUILDER" "$DOWNLOADS"

python3 - "$DOWNLOADS" "$EXTRACTED" <<'PY'
from pathlib import Path
import sys
import tarfile
import zipfile

downloads = Path(sys.argv[1])
extracted = Path(sys.argv[2])
required_templates = {
    'starter/.gitignore',
    'starter/pubspec.yaml.tmpl',
    'starter/README.md.tmpl',
    'starter/lib/package.dart.tmpl',
    'starter/lib/src/module.dart.tmpl',
    'starter/lib/src/typed_module.dart.tmpl',
    'starter/test/module_test.dart.tmpl',
    'starter/test/typed_module_test.dart.tmpl',
}

for platform, launcher, absent_launcher in (
    ('linux', 'rohd_create/rohd_create.sh', 'rohd_create/rohd_create.ps1'),
    ('windows', 'rohd_create/rohd_create.ps1', 'rohd_create/rohd_create.sh'),
):
    archive_path = downloads / f'rohd_create_{platform}.zip'
    with zipfile.ZipFile(archive_path) as archive:
        names = set(archive.namelist())
        missing = {launcher, 'rohd_create/starter.tar.gz'} - names
        if missing:
            raise SystemExit(
                f'{archive_path} is missing: {sorted(missing)}'
            )
        if absent_launcher in names:
            raise SystemExit(
                f'{archive_path} unexpectedly contains {absent_launcher}'
            )
        if platform == 'linux':
            archive.extractall(extracted)
            with tarfile.open(
                extracted / 'rohd_create' / 'starter.tar.gz',
                mode='r:gz',
            ) as starter:
                missing_templates = required_templates - set(starter.getnames())
                if missing_templates:
                    raise SystemExit(
                        f'{archive_path} starter archive is missing: '
                        f'{sorted(missing_templates)}'
                    )
PY

chmod +x "$EXTRACTED/rohd_create/rohd_create.sh"
PATH="/usr/bin:/bin" bash "$EXTRACTED/rohd_create/rohd_create.sh" \
  "$DESTINATION" \
  --package-name my_first_module \
  --module-name MyFirstModule \
  --skip-pub-get

test -f "$DESTINATION/lib/src/my_first_module.dart"
test -f "$DESTINATION/lib/src/my_first_module_typed.dart"
test -f "$DESTINATION/test/my_first_module_test.dart"
test -f "$DESTINATION/test/my_first_module_typed_test.dart"
grep -F "import 'package:rohd/rohd.dart';" \
  "$DESTINATION/lib/src/my_first_module.dart" > /dev/null

echo 'ROHD Create bundle checks passed.'
