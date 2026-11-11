#!/usr/bin/env python3
# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#
# build_rohd_create_bundles.py
# Builds platform-specific ROHD Create bundles from the editable starter area.
#
# 2026 October 25
# Author: Desmond A. Kirkpatrick <desmond.a.kirkpatrick@intel.com>

"""Build the downloadable ROHD Create platform bundles."""

from __future__ import annotations

import argparse
from pathlib import Path
import tarfile
import tempfile
import zipfile


SOURCE_ROOT = Path(__file__).resolve().parent / "rohd_create_template"
STARTER_ROOT = SOURCE_ROOT / "starter"
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / "docs" / "assets" / "downloads"


def validate_source() -> None:
  required_paths = (
      SOURCE_ROOT / "rohd_create.sh",
      SOURCE_ROOT / "rohd_create.ps1",
      STARTER_ROOT / ".gitignore",
      STARTER_ROOT / "pubspec.yaml.tmpl",
      STARTER_ROOT / "README.md.tmpl",
      STARTER_ROOT / "lib" / "package.dart.tmpl",
      STARTER_ROOT / "lib" / "src" / "module.dart.tmpl",
      STARTER_ROOT / "lib" / "src" / "typed_module.dart.tmpl",
      STARTER_ROOT / "test" / "module_test.dart.tmpl",
      STARTER_ROOT / "test" / "typed_module_test.dart.tmpl",
  )
  missing = [path for path in required_paths if not path.is_file()]
  if missing:
    joined = ", ".join(str(path) for path in missing)
    raise FileNotFoundError(f"Missing ROHD Create bundle source: {joined}")


def create_starter_archive(path: Path) -> None:
  with tarfile.open(path, mode="w:gz") as archive:
    archive.add(STARTER_ROOT, arcname="starter")


def create_bundle(
    output_dir: Path,
    platform: str,
    launcher: str,
    starter_archive: Path,
) -> Path:
  bundle = output_dir / f"rohd_create_{platform}.zip"
  with zipfile.ZipFile(
      bundle,
      mode="w",
      compression=zipfile.ZIP_DEFLATED,
      compresslevel=9,
  ) as archive:
    archive.write(SOURCE_ROOT / launcher, f"rohd_create/{launcher}")
    archive.write(starter_archive, "rohd_create/starter.tar.gz")
  return bundle


def main() -> None:
  parser = argparse.ArgumentParser(
      description="Build ROHD Create platform download bundles."
  )
  parser.add_argument(
      "output_directory",
      nargs="?",
      type=Path,
      default=DEFAULT_OUTPUT,
      help="Directory receiving the Linux and Windows ZIP bundles.",
  )
  args = parser.parse_args()

  validate_source()
  output_dir = args.output_directory.resolve()
  output_dir.mkdir(parents=True, exist_ok=True)

  with tempfile.TemporaryDirectory(prefix="rohd-create-starter-") as temporary:
    starter_archive = Path(temporary) / "starter.tar.gz"
    create_starter_archive(starter_archive)
    for platform, launcher in (
        ("linux", "rohd_create.sh"),
        ("windows", "rohd_create.ps1"),
    ):
      bundle = create_bundle(output_dir, platform, launcher, starter_archive)
      print(f"Wrote {bundle}")


if __name__ == "__main__":
  main()
