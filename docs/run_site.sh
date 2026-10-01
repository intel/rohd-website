#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd -- "${script_dir}"
exec bundle exec ruby -r"${script_dir}/tool/webrick_range_fix.rb" \
  -S jekyll serve --future --host 0.0.0.0 "$@"
