#!/bin/bash

# Copyright (C) 2023 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#
# update_directory.sh
# GitHub Actions step: Set up the files directory
#
# 2023 May 3
# Author: Yao Jing Quek <yao.jing.quek@intel.com>

set -euo pipefail

root_directory=$(git rev-parse --show-toplevel)

src_path="$root_directory/src"
rohd_submodule_path="$root_directory/rohd"

git submodule update --init --recursive
git submodule update --remote rohd

for directory in "$rohd_submodule_path/doc/website"/*; do
    directory_name=$(basename "$directory")

    if [ -d "$src_path/$directory_name" ]; then
        echo "directory exist, removing the old directory before copy."
        rm -r "$src_path/$directory_name"
    else
        # Create a symlink in the src directory
        echo "directory not exist, proceed to copy."
    fi

    cp -r "$directory" "$src_path/$directory_name"
done

