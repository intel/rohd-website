# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$websiteRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) (
  "rohd-create-integration-$([System.Guid]::NewGuid())"
)

try {
  $bundleDirectory = Join-Path $fixture 'bundles'
  $launcherDirectory = Join-Path $fixture 'launcher'
  $destination = Join-Path $fixture 'test'

  & python (Join-Path $websiteRoot 'tool/build_rohd_create_bundles.py') $bundleDirectory
  if ($LASTEXITCODE -ne 0) {
    throw 'ROHD Create bundle build failed.'
  }
  Expand-Archive `
    -LiteralPath (Join-Path $bundleDirectory 'rohd_create_windows.zip') `
    -DestinationPath $launcherDirectory
  & (Join-Path $launcherDirectory 'rohd_create/rohd_create.ps1') $destination `
    -PackageName my_first_module `
    -ModuleName MyFirstModule
  if ($LASTEXITCODE -ne 0) {
    throw 'ROHD Create launcher failed.'
  }

  Push-Location $destination
  try {
    & dart analyze
    if ($LASTEXITCODE -ne 0) {
      throw 'Generated package analysis failed.'
    }
    & dart test
    if ($LASTEXITCODE -ne 0) {
      throw 'Generated package tests failed.'
    }
  } finally {
    Pop-Location
  }
} finally {
  if (Test-Path -LiteralPath $fixture) {
    Remove-Item -LiteralPath $fixture -Recurse -Force
  }
}

Write-Output 'ROHD Create generated package checks passed.'
