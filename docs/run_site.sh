#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
website_root="$(cd -- "${script_dir}/.." && pwd)"

python3 "${website_root}/tool/build_rohd_create_bundles.py"
cd -- "${script_dir}"
exec bundle exec ruby -r"${script_dir}/tool/webrick_range_fix.rb" \
  -r"${script_dir}/tool/webrick_chrome_devtools_probe.rb" \
  -e 'load Gem.bin_path("jekyll", "jekyll")' -- \
  serve --future --host 0.0.0.0 "$@"
