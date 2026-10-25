#!/usr/bin/env bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#
# rohd_create_test.sh
# Tests the standalone Bash ROHD development-area bootstrapper.
#
# 2026 October 25
# Author: Desmond A. Kirkpatrick <desmond.a.kirkpatrick@intel.com>

set -euo pipefail

readonly WEBSITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly BUNDLE_BUILDER="$WEBSITE_ROOT/tool/build_rohd_create_bundles.py"
readonly FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT
readonly DOWNLOAD_DIRECTORY="$FIXTURE/download"
readonly BUNDLE_DIRECTORY="$FIXTURE/bundles"
readonly GENERATOR="$DOWNLOAD_DIRECTORY/rohd_create/rohd_create.sh"
readonly BIN_DIRECTORY="$FIXTURE/bin"
readonly ROHD="$FIXTURE/rohd"
readonly HCL="$FIXTURE/rohd-hcl"
readonly VF="$FIXTURE/rohd-vf"
readonly DESTINATION="$FIXTURE/development area"
readonly OVERRIDE_DESTINATION="$FIXTURE/override area"
readonly FORMATTED_DESTINATION="$FIXTURE/formatted area"
readonly DART_CALL_LOG="$FIXTURE/dart_calls"

mkdir -p \
  "$DOWNLOAD_DIRECTORY" \
  "$BIN_DIRECTORY" \
  "$ROHD/packages/rohd_hierarchy" \
  "$HCL" \
  "$VF"
python3 "$BUNDLE_BUILDER" "$BUNDLE_DIRECTORY"
python3 - "$BUNDLE_DIRECTORY/rohd_create_linux.zip" "$DOWNLOAD_DIRECTORY" <<'PY'
from pathlib import Path
import sys
import zipfile

with zipfile.ZipFile(Path(sys.argv[1])) as bundle:
  bundle.extractall(Path(sys.argv[2]))
PY
chmod +x "$GENERATOR"

cat > "$BIN_DIRECTORY/git" <<'SH'
#!/usr/bin/env bash
echo 'Git must not run for a hosted development area.' >&2
exit 99
SH
chmod +x "$BIN_DIRECTORY/git"

cat > "$ROHD/pubspec.yaml" <<'YAML'
name: rohd
version: 0.6.11
YAML
cat > "$ROHD/packages/rohd_hierarchy/pubspec.yaml" <<'YAML'
name: rohd_hierarchy
version: 0.1.1
YAML
cat > "$HCL/pubspec.yaml" <<'YAML'
name: rohd_hcl
version: 0.3.0
YAML
cat > "$VF/pubspec.yaml" <<'YAML'
name: rohd_vf
version: 0.6.0
YAML

"$GENERATOR" --help > "$FIXTURE/help"
grep -F 'The launcher must remain beside its bundled starter.tar.gz archive.' \
  "$FIXTURE/help" > /dev/null
grep -F 'the generated package resolves compatible published versions of ROHD,' \
  "$FIXTURE/help" > /dev/null
grep -F 'ROHD-HCL, and ROHD-VF from pub.dev.' "$FIXTURE/help" > /dev/null
grep -F 'OUTPUT_DIRECTORY is the new package directory.' "$FIXTURE/help" > /dev/null
grep -F -- '--rohd-path PATH' "$FIXTURE/help" > /dev/null
grep -F -- '--hcl-path PATH' "$FIXTURE/help" > /dev/null
grep -F -- '--vf-path PATH' "$FIXTURE/help" > /dev/null
if grep -F -- '--workspace' "$FIXTURE/help" > /dev/null; then
  echo 'Hosted bootstrapper must not expose clone workspace options.' >&2
  exit 1
fi

if PATH="$BIN_DIRECTORY:/usr/bin:/bin" /bin/bash "$GENERATOR" \
  "$FIXTURE/no-dart" > "$FIXTURE/no-dart.out" 2> "$FIXTURE/no-dart.err"; then
  echo 'Expected the default bootstrap to require Dart.' >&2
  exit 1
fi
grep -F 'Dart SDK was not found on PATH.' "$FIXTURE/no-dart.err" > /dev/null
grep -F 'choco install dart-sdk' "$FIXTURE/no-dart.err" > /dev/null

cat > "$BIN_DIRECTORY/dart" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${DART_CALL_LOG:-}" ]]; then
  printf '%s\n' "${1:-}" >> "$DART_CALL_LOG"
fi

case "${1:-}" in
  --version)
    printf 'Dart SDK version: %s (stable) on "Linux"\n' \
      "${FAKE_DART_VERSION:-3.6.0}" >&2
    ;;
  format|pub)
    ;;
  *)
    echo "Unexpected fake Dart command: $*" >&2
    exit 99
    ;;
esac
SH
chmod +x "$BIN_DIRECTORY/dart"

if FAKE_DART_VERSION=3.5.0 PATH="$BIN_DIRECTORY:/usr/bin:/bin" \
  /bin/bash "$GENERATOR" "$FIXTURE/incompatible-dart" \
  > "$FIXTURE/incompatible.out" 2> "$FIXTURE/incompatible.err"; then
  echo 'Expected an incompatible Dart SDK to be rejected.' >&2
  exit 1
fi
grep -F 'Dart 3.5.0 is incompatible with this launcher.' \
  "$FIXTURE/incompatible.err" > /dev/null
grep -F 'requires Dart >=3.6.0 and <4.0.0' "$FIXTURE/incompatible.err" > /dev/null

FAKE_DART_VERSION=3.6.0 PATH="$BIN_DIRECTORY:/usr/bin:/bin" \
  /bin/bash "$GENERATOR" "$FIXTURE/supported-dart" \
  --package-name supported_dart \
  --module-name SupportedDart \
  --skip-pub-get > "$FIXTURE/supported.out"
test -f "$FIXTURE/supported-dart/lib/src/supported_dart.dart"

env DART_CALL_LOG="$DART_CALL_LOG" FAKE_DART_VERSION=3.6.0 \
  PATH="$BIN_DIRECTORY:/usr/bin:/bin" /bin/bash "$GENERATOR" \
  "$FORMATTED_DESTINATION" \
  --package-name formatted_dart \
  --module-name FormattedDart > "$FIXTURE/formatted.out"
pub_line="$(grep -n '^pub$' "$DART_CALL_LOG" | cut -d: -f1)"
format_line="$(grep -n '^format$' "$DART_CALL_LOG" | cut -d: -f1)"
if [[ -z "$pub_line" || -z "$format_line" || "$pub_line" -ge "$format_line" ]]; then
  echo 'The launcher must resolve Pub dependencies before formatting source.' >&2
  exit 1
fi

PATH="$BIN_DIRECTORY:/usr/bin:/bin" /bin/bash "$GENERATOR" "$DESTINATION" \
  --package-name starter_ports \
  --module-name StarterPorts \
  --skip-pub-get > "$FIXTURE/create.out"

readonly PUBSPEC="$DESTINATION/pubspec.yaml"
readonly MODULE="$DESTINATION/lib/src/starter_ports.dart"
readonly TYPED_MODULE="$DESTINATION/lib/src/starter_ports_typed.dart"
readonly TEST="$DESTINATION/test/starter_ports_test.dart"
readonly TYPED_TEST="$DESTINATION/test/starter_ports_typed_test.dart"
readonly GITIGNORE="$DESTINATION/.gitignore"
readonly README="$DESTINATION/README.md"

grep -F 'name: starter_ports' "$PUBSPEC" > /dev/null
grep -F 'rohd: ^0.6.11' "$PUBSPEC" > /dev/null
grep -F 'rohd_hcl: ^0.2.1' "$PUBSPEC" > /dev/null
grep -F 'rohd_vf: ^0.6.0' "$PUBSPEC" > /dev/null
if grep -F 'dependency_overrides:' "$PUBSPEC" > /dev/null; then
  echo 'Hosted bootstrapper unexpectedly emitted local dependency overrides.' >&2
  exit 1
fi
if [[ -e "$DESTINATION/.rohd-development" ]]; then
  echo 'Hosted bootstrapper unexpectedly created a clone workspace.' >&2
  exit 1
fi
grep -F "export 'src/starter_ports_typed.dart';" \
  "$DESTINATION/lib/starter_ports.dart" > /dev/null
grep -F "final invertPin = tryInput('invert');" "$MODULE" > /dev/null
grep -F "dataIn = addInput('dataIn', dataIn);" "$MODULE" > /dev/null
grep -F 'Combinational([' "$MODULE" > /dev/null
grep -F 'When the optional `invert` input is absent' "$MODULE" > /dev/null
grep -F 'StarterPorts passes through without an invert input' "$TEST" > /dev/null
grep -F 'StarterPorts conditionally inverts with an invert input' "$TEST" > /dev/null
grep -F "dut.tryInput('invert')" "$TEST" > /dev/null
grep -F "WaveDumper(dut, outputPath: waveformPath);" "$TEST" > /dev/null
grep -F "const waveformPath = 'tmp_test/starter_ports_conditional.vcd';" \
  "$TEST" > /dev/null
grep -Fx 'tmp_test/' "$GITIGNORE" > /dev/null
grep -F 'class StarterPortsTyped extends Module' "$TYPED_MODULE" > /dev/null
grep -F 'LogicArray get arrayOut' "$TYPED_MODULE" > /dev/null
grep -F 'addInterfacePorts(' "$TYPED_MODULE" > /dev/null
grep -F 'class _StarterPortsTypedPortInverter extends Module' \
  "$TYPED_MODULE" > /dev/null
grep -F 'final arrayIn = addInputArray(' "$TYPED_MODULE" > /dev/null
grep -F 'final arrayResult = LogicArray(' "$TYPED_MODULE" > /dev/null
grep -F 'arrayOut.elements[index] <= arrayResult.elements[index];' \
  "$TYPED_MODULE" > /dev/null
grep -F 'Combinational([' "$TYPED_MODULE" > /dev/null
grep -F 'dimensions: const [2],' "$TYPED_MODULE" > /dev/null
grep -F 'elementWidth: 4,' "$TYPED_MODULE" > /dev/null
grep -F 'numUnpackedDimensions: 1,' "$TYPED_MODULE" > /dev/null
grep -F 'arrayOut.elements[index] <= child.arrayOut.elements[index];' \
  "$TYPED_MODULE" > /dev/null
grep -F 'StarterPortsTyped conditionally processes typed ports' \
  "$TYPED_TEST" > /dev/null
grep -F 'input logic [3:0] arrayIn [1:0]' "$TYPED_TEST" > /dev/null
grep -F "WaveDumper(dut, outputPath: waveformPath);" "$TYPED_TEST" > /dev/null
grep -F "const waveformPath = 'tmp_test/starter_ports_typed.vcd';" \
  "$TYPED_TEST" > /dev/null
grep -F 'ROHD hardware skill' "$README" > /dev/null
skill_link_count="$(awk '
  /https:\/\/github\.com\/intel\/rohd\/blob\/main\/\.github\/skills\// {
    count++
  }
  END {
    print count + 0
  }
' "$README")"
if [[ "$skill_link_count" -ne 1 ]]; then
  echo 'Generated README must contain exactly one ROHD skill link.' >&2
  exit 1
fi
grep -F "dut.generateSynth()" "$TYPED_TEST" > /dev/null
grep -F "unawaited(Simulator.run());" "$TYPED_TEST" > /dev/null
grep -F "await clk.nextNegedge;" "$TYPED_TEST" > /dev/null
grep -F 'structureIn.flag.inject(0);' "$TYPED_TEST" > /dev/null
grep -F 'control.signalIn.inject(0);' "$TYPED_TEST" > /dev/null
grep -F 'Simulator.registerAction(Simulator.time + 1, () {' \
  "$TYPED_TEST" > /dev/null
grep -F 'invert.put(0);' "$TYPED_TEST" > /dev/null
grep -F "contains(r'\$enddefinitions')" "$TYPED_TEST" > /dev/null
if grep -Eq 'Copyright|SPDX-License-Identifier|Author:' \
  "$MODULE" "$TYPED_MODULE" "$TEST" "$TYPED_TEST"; then
  echo 'Generated user source must not contain ROHD ownership headers.' >&2
  exit 1
fi

PATH="$BIN_DIRECTORY:/usr/bin:/bin" /bin/bash "$GENERATOR" "$OVERRIDE_DESTINATION" \
  --package-name override_ports \
  --module-name OverridePorts \
  --rohd-path "$ROHD" \
  --hcl-path "$HCL" \
  --vf-path "$VF" \
  --skip-pub-get > "$FIXTURE/override.out"

grep -F 'rohd_hcl: ^0.3.0' "$OVERRIDE_DESTINATION/pubspec.yaml" > /dev/null
grep -F 'dependency_overrides:' "$OVERRIDE_DESTINATION/pubspec.yaml" > /dev/null
grep -F "path: '$(realpath --relative-to="$OVERRIDE_DESTINATION" "$ROHD")'" \
  "$OVERRIDE_DESTINATION/pubspec.yaml" > /dev/null
grep -F "path: '$(realpath --relative-to="$OVERRIDE_DESTINATION" "$HCL")'" \
  "$OVERRIDE_DESTINATION/pubspec.yaml" > /dev/null
grep -F "path: '$(realpath --relative-to="$OVERRIDE_DESTINATION" "$VF")'" \
  "$OVERRIDE_DESTINATION/pubspec.yaml" > /dev/null
grep -F \
  "path: '$(realpath --relative-to="$OVERRIDE_DESTINATION" "$ROHD/packages/rohd_hierarchy")'" \
  "$OVERRIDE_DESTINATION/pubspec.yaml" > /dev/null

echo 'Standalone Bash ROHD development-area bootstrapper checks passed.'
