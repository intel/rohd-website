#!/usr/bin/env bash
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#
# rohd_create.sh
# Creates a standalone ROHD development package from bundled starter templates.
#
# 2026 October 25
# Author: Desmond A. Kirkpatrick <desmond.a.kirkpatrick@intel.com>

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly STARTER_ARCHIVE="$SCRIPT_DIR/starter.tar.gz"
readonly DEFAULT_ROHD_VERSION='0.6.11'
readonly DEFAULT_HCL_VERSION='0.2.1'
readonly DEFAULT_VF_VERSION='0.6.0'
readonly DART_MINIMUM_MAJOR=3
readonly DART_MINIMUM_MINOR=6

destination=''
package_name=''
module_name='MyModule'
rohd_path="${ROHD_PATH:-}"
hcl_path="${ROHD_HCL_PATH:-}"
vf_path="${ROHD_VF_PATH:-}"
skip_pub_get=false
starter_temp=''
template_dir=''

usage() {
  cat <<'USAGE'
Create a standalone ROHD development package with ROHD-HCL and ROHD-VF support.

Usage:
  rohd_create.sh OUTPUT_DIRECTORY [options]

OUTPUT_DIRECTORY is the new package directory. It may be absent or empty, but
the script never chooses a default output location or overwrites its contents.

Options:
  --package-name NAME  Dart package name (defaults to the destination name)
  --module-name NAME   Module class name (defaults to MyModule)
  --rohd-path PATH     Use this local ROHD checkout instead of pub.dev
  --hcl-path PATH      Use this local ROHD-HCL checkout instead of pub.dev
  --vf-path PATH       Use this local ROHD-VF checkout instead of pub.dev
  --skip-pub-get       Create the package without requiring Dart or resolving Pub
  -h, --help           Show this help

The launcher must remain beside its bundled starter.tar.gz archive. By default,
the generated package resolves compatible published versions of ROHD,
ROHD-HCL, and ROHD-VF from pub.dev. A supplied local checkout becomes a
dependency override, allowing source development without changing imports.

The path options can also be supplied through ROHD_PATH, ROHD_HCL_PATH, and
ROHD_VF_PATH environment variables.

Dart is required by default to format the starter and run `dart pub get`.
Use --skip-pub-get only when you deliberately want to prepare the package
before installing Dart or resolving dependencies.
USAGE
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

cleanup() {
  if [[ -n "$starter_temp" && -d "$starter_temp" ]]; then
    rm -rf "$starter_temp"
  fi
}
trap cleanup EXIT

expand_home_path() {
  case "$1" in
    '~') printf '%s\n' "$HOME" ;;
    '~/'*) printf '%s/%s\n' "$HOME" "${1:2}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

yaml_quote() {
  local escaped
  escaped="$(printf '%s' "$1" | sed "s/'/''/g")"
  printf "'%s'" "$escaped"
}

show_dart_setup_help() {
  cat >&2 <<'HELP'
Dart SDK was not found on PATH.

Install Dart, reopen your terminal, and rerun this command:
  https://dart.dev/get-dart

Windows PowerShell:
  winget install Dart.DartSDK
  # Or, after installing Chocolatey:
  choco install dart-sdk

macOS:
  brew tap dart-lang/dart
  brew install dart

Linux:
  Follow the distribution-specific instructions at https://dart.dev/get-dart.

A Flutter SDK also includes Dart when its `bin` directory is on PATH.
HELP
}

ensure_dart() {
  if ! command -v dart >/dev/null; then
    show_dart_setup_help
    fail 'Install Dart or rerun with --skip-pub-get to create an unresolved scaffold.'
  fi

  local dart_version
  dart_version="$(get_dart_version)" ||
    fail 'Could not determine the installed Dart SDK version.'
  [[ -n "$dart_version" ]] ||
    fail 'Could not determine the installed Dart SDK version.'
  if ! dart_version_is_supported "$dart_version"; then
    show_dart_version_help "$dart_version"
    fail "Dart $dart_version is unsupported; install Dart >=3.6.0 and <4.0.0."
  fi
}

get_dart_version() {
  dart --version 2>&1 |
    sed -nE 's/.*version: ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' |
    head -n 1
}

dart_version_is_supported() {
  local version="$1"
  local major minor patch
  IFS=. read -r major minor patch <<<"$version"
  [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ && "$patch" =~ ^[0-9]+$ ]] ||
    return 1
  ((major == DART_MINIMUM_MAJOR && minor >= DART_MINIMUM_MINOR))
}

show_dart_version_help() {
  local version="$1"
  cat >&2 <<HELP
Dart $version is incompatible with this launcher.

The generated package requires Dart >=3.6.0 and <4.0.0.
Install a compatible SDK from https://dart.dev/get-dart, reopen your terminal,
and rerun this command.
HELP
}

validate_package_checkout() {
  local label="$1"
  local expected_name="$2"
  local checkout="$3"
  local manifest="$checkout/pubspec.yaml"

  [[ -f "$manifest" ]] &&
    grep -Eq "^name:[[:space:]]*$expected_name[[:space:]]*$" "$manifest" ||
    fail "$label checkout must contain a package named $expected_name: $checkout"
}

resolve_local_checkout() {
  local label="$1"
  local expected_name="$2"
  local candidate="$3"

  candidate="$(realpath -e -- "$(expand_home_path "$candidate")")" ||
    fail "$label checkout not found: $candidate"
  validate_package_checkout "$label" "$expected_name" "$candidate"
  printf 'Using local %s checkout: %s\n' "$label" "$candidate" >&2
  printf '%s\n' "$candidate"
}

package_version() {
  awk '$1 == "version:" {print $2; exit}' "$1"
}

verify_templates() {
  local required
  for required in \
    "$template_dir/.gitignore" \
    "$template_dir/pubspec.yaml.tmpl" \
    "$template_dir/README.md.tmpl" \
    "$template_dir/lib/package.dart.tmpl" \
    "$template_dir/lib/src/module.dart.tmpl" \
    "$template_dir/lib/src/typed_module.dart.tmpl" \
    "$template_dir/test/module_test.dart.tmpl" \
    "$template_dir/test/typed_module_test.dart.tmpl"; do
    [[ -f "$required" ]] ||
      fail "Launcher bundle is incomplete; missing template: $required"
  done
}

extract_starter() {
  [[ -f "$STARTER_ARCHIVE" ]] ||
    fail "Launcher bundle is incomplete; missing starter archive: $STARTER_ARCHIVE"
  command -v tar >/dev/null ||
    fail 'The launcher bundle requires tar. Install tar, then rerun the launcher.'

  starter_temp="$(mktemp -d)"
  if ! tar -xzf "$STARTER_ARCHIVE" -C "$starter_temp"; then
    fail 'Could not extract the bundled starter area.'
  fi
  template_dir="$starter_temp/starter"
  verify_templates
}

render_template() {
  local source="$1"
  local output="$2"

  sed \
    -e "s/__PACKAGE_NAME__/$package_name/g" \
    -e "s/__MODULE_NAME__/$module_name/g" \
    -e "s/__MODULE_FILE__/$module_file/g" \
    -e "s/__ROHD_VERSION__/$rohd_version/g" \
    -e "s/__HCL_VERSION__/$hcl_version/g" \
    -e "s/__VF_VERSION__/$vf_version/g" \
    "$source" >"$output"
}

while (($#)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --package-name|--module-name|--rohd-path|--hcl-path|--vf-path)
      option="$1"
      shift
      (($#)) || fail "Missing value for $option."
      case "$option" in
        --package-name) package_name="$1" ;;
        --module-name) module_name="$1" ;;
        --rohd-path) rohd_path="$1" ;;
        --hcl-path) hcl_path="$1" ;;
        --vf-path) vf_path="$1" ;;
      esac
      ;;
    --skip-pub-get)
      skip_pub_get=true
      ;;
    --*)
      fail "Unknown option: $1. Run with --help for usage."
      ;;
    *)
      if [[ -n "$destination" ]]; then
        fail 'Only one destination may be specified.'
      fi
      destination="$1"
      ;;
  esac
  shift
done

[[ -n "$destination" ]] || {
  usage >&2
  exit 2
}
extract_starter

destination="$(realpath -m -- "$(expand_home_path "$destination")")"
if [[ -e "$destination" ]]; then
  [[ -d "$destination" ]] || fail 'Destination exists and is not a directory.'
  [[ -z "$(find "$destination" -mindepth 1 -maxdepth 1 -print -quit)" ]] ||
    fail "Destination is not empty: $destination"
fi

if [[ "$skip_pub_get" == false ]]; then
  ensure_dart
fi

rohd_version="$DEFAULT_ROHD_VERSION"
hcl_version="$DEFAULT_HCL_VERSION"
vf_version="$DEFAULT_VF_VERSION"
rohd_hierarchy_path=''

if [[ -n "$rohd_path" ]]; then
  rohd_path="$(resolve_local_checkout 'ROHD' 'rohd' "$rohd_path")"
  rohd_hierarchy_path="$rohd_path/packages/rohd_hierarchy"
  validate_package_checkout 'ROHD' 'rohd_hierarchy' "$rohd_hierarchy_path"
  rohd_version="$(package_version "$rohd_path/pubspec.yaml")"
fi
if [[ -n "$hcl_path" ]]; then
  hcl_path="$(resolve_local_checkout 'ROHD-HCL' 'rohd_hcl' "$hcl_path")"
  hcl_version="$(package_version "$hcl_path/pubspec.yaml")"
fi
if [[ -n "$vf_path" ]]; then
  vf_path="$(resolve_local_checkout 'ROHD-VF' 'rohd_vf' "$vf_path")"
  vf_version="$(package_version "$vf_path/pubspec.yaml")"
fi
[[ -n "$rohd_version" && -n "$hcl_version" && -n "$vf_version" ]] ||
  fail 'Could not read a local framework package version.'

if [[ -z "$package_name" ]]; then
  package_name="${destination##*/}"
  package_name="${package_name,,}"
  package_name="${package_name//-/_}"
  package_name="$(printf '%s' "$package_name" |
    sed -E 's/[^a-z0-9_]+/_/g; s/_+/_/g; s/^_+|_+$//g')"
  [[ "$package_name" =~ ^[a-z] ]] || package_name="rohd_${package_name}"
fi
[[ "$package_name" =~ ^[a-z][a-z0-9_]*$ ]] ||
  fail "Invalid Dart package name: $package_name"
[[ "$module_name" =~ ^[A-Z][A-Za-z0-9]*$ ]] ||
  fail 'Module name must be a PascalCase Dart identifier.'

mkdir -p "$destination"
module_file="$(printf '%s' "$module_name" |
  sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' |
  tr '[:upper:]' '[:lower:]')"
if [[ -n "$rohd_path" ]]; then
  rohd_relative="$(realpath --relative-to="$destination" "$rohd_path")"
  hierarchy_relative="$(realpath --relative-to="$destination" "$rohd_hierarchy_path")"
fi
if [[ -n "$hcl_path" ]]; then
  hcl_relative="$(realpath --relative-to="$destination" "$hcl_path")"
fi
if [[ -n "$vf_path" ]]; then
  vf_relative="$(realpath --relative-to="$destination" "$vf_path")"
fi

mkdir -p "$destination/lib/src" "$destination/test"
cp "$template_dir/.gitignore" "$destination/.gitignore"
render_template "$template_dir/pubspec.yaml.tmpl" "$destination/pubspec.yaml"
render_template "$template_dir/lib/package.dart.tmpl" \
  "$destination/lib/$package_name.dart"
render_template "$template_dir/lib/src/module.dart.tmpl" \
  "$destination/lib/src/$module_file.dart"
render_template "$template_dir/lib/src/typed_module.dart.tmpl" \
  "$destination/lib/src/${module_file}_typed.dart"
render_template "$template_dir/test/module_test.dart.tmpl" \
  "$destination/test/${module_file}_test.dart"
render_template "$template_dir/test/typed_module_test.dart.tmpl" \
  "$destination/test/${module_file}_typed_test.dart"
render_template "$template_dir/README.md.tmpl" "$destination/README.md"

if [[ -n "$rohd_path" || -n "$hcl_path" || -n "$vf_path" ]]; then
  cat >>"$destination/pubspec.yaml" <<'YAML'

dependency_overrides:
YAML
  if [[ -n "$rohd_path" ]]; then
    cat >>"$destination/pubspec.yaml" <<YAML
  rohd:
    path: $(yaml_quote "$rohd_relative")
  rohd_hierarchy:
    path: $(yaml_quote "$hierarchy_relative")
YAML
  fi
  if [[ -n "$hcl_path" ]]; then
    cat >>"$destination/pubspec.yaml" <<YAML
  rohd_hcl:
    path: $(yaml_quote "$hcl_relative")
YAML
  fi
  if [[ -n "$vf_path" ]]; then
    cat >>"$destination/pubspec.yaml" <<YAML
  rohd_vf:
    path: $(yaml_quote "$vf_relative")
YAML
  fi
fi

if [[ "$skip_pub_get" == false ]]; then
  printf 'Resolving Dart dependencies in %s\n' "$destination"
  if ! (cd "$destination" && dart pub get); then
    fail 'Dart dependency resolution failed. The generated package remains available for inspection.'
  fi
fi

if command -v dart >/dev/null && dart_version="$(get_dart_version)" &&
  dart_version_is_supported "$dart_version"; then
  if [[ "$skip_pub_get" == false ]]; then
    (cd "$destination" && dart format lib test) >/dev/null
  else
    dart format "$destination/lib" "$destination/test" >/dev/null
  fi
elif command -v dart >/dev/null; then
  printf 'Warning: installed Dart is incompatible; run dart format lib test after installing Dart >=3.6.0 and <4.0.0.\n' >&2
else
  printf 'Warning: Dart was not found; run dart format lib test after creation.\n' >&2
fi

printf 'Created ROHD development area: %s\n' "$destination"
printf 'Package: %s\nModule: %s\n' "$package_name" "$module_name"
if [[ -n "$rohd_path" ]]; then
  printf 'ROHD local override: %s\n' "$rohd_path"
else
  printf 'ROHD hosted constraint: ^%s\n' "$rohd_version"
fi
if [[ -n "$hcl_path" ]]; then
  printf 'ROHD-HCL local override: %s\n' "$hcl_path"
else
  printf 'ROHD-HCL hosted constraint: ^%s\n' "$hcl_version"
fi
if [[ -n "$vf_path" ]]; then
  printf 'ROHD-VF local override: %s\n' "$vf_path"
else
  printf 'ROHD-VF hosted constraint: ^%s\n' "$vf_version"
fi
if [[ "$skip_pub_get" == true ]]; then
  printf 'Dependencies were not resolved. Run: cd %s && dart pub get\n' "$destination"
else
  printf 'Next: cd %s && dart test\n' "$destination"
fi
