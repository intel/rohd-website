# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#
# rohd_create.ps1
# Creates a standalone ROHD development package from bundled starter templates.
#
# 2026 October 25
# Author: Desmond A. Kirkpatrick <desmond.a.kirkpatrick@intel.com>

[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Destination,

  [Alias('package-name')]
  [string]$PackageName = '',

  [Alias('module-name')]
  [string]$ModuleName = 'MyModule',

  [Alias('rohd-path')]
  [string]$RohdPath = $env:ROHD_PATH,

  [Alias('hcl-path')]
  [string]$HclPath = $env:ROHD_HCL_PATH,

  [Alias('vf-path')]
  [string]$VfPath = $env:ROHD_VF_PATH,

  [Alias('skip-pub-get')]
  [switch]$SkipPubGet,

  [Alias('h', '?')]
  [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = $PSScriptRoot
$StarterArchive = Join-Path $ScriptRoot 'starter.tar.gz'
$script:TemplateRoot = $null
$script:TemplateWorkDirectory = $null
$DefaultRohdVersion = '0.6.11'
$DefaultHclVersion = '0.2.1'
$DefaultVfVersion = '0.6.0'
$DartMinimumMajor = 3
$DartMinimumMinor = 6
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Show-Usage {
  @'
Create a standalone ROHD development package with ROHD-HCL and ROHD-VF support.

Usage:
  .\rohd_create.ps1 OUTPUT_DIRECTORY [options]

OUTPUT_DIRECTORY is the new package directory. It may be absent or empty, but
the script never chooses a default output location or overwrites its contents.

Options:
  -PackageName NAME  Dart package name (defaults to the destination name)
  -ModuleName NAME   Module class name (defaults to MyModule)
  -RohdPath PATH     Use this local ROHD checkout instead of pub.dev
  -HclPath PATH      Use this local ROHD-HCL checkout instead of pub.dev
  -VfPath PATH       Use this local ROHD-VF checkout instead of pub.dev
  -SkipPubGet        Create the package without requiring Dart or resolving Pub
  -Help              Show this help

The launcher must remain beside its bundled starter.tar.gz archive. By default,
the generated package resolves compatible published versions of ROHD,
ROHD-HCL, and ROHD-VF from pub.dev. A supplied local checkout becomes a
dependency override, allowing source development without changing imports.

The path options can also be supplied through ROHD_PATH, ROHD_HCL_PATH, and
ROHD_VF_PATH environment variables.
'@ | Write-Output
}

function Fail {
  param([Parameter(Mandatory = $true)][string]$Message)

  Cleanup-Starter
  [Console]::Error.WriteLine("Error: $Message")
  exit 1
}

function Cleanup-Starter {
  if ($null -ne $script:TemplateWorkDirectory -and
      (Test-Path -LiteralPath $script:TemplateWorkDirectory)) {
    Remove-Item -LiteralPath $script:TemplateWorkDirectory -Recurse -Force
  }
}

function Expand-HomePath {
  param([Parameter(Mandatory = $true)][string]$Path)

  $expanded = [Environment]::ExpandEnvironmentVariables($Path)
  if ($expanded -eq '~') {
    return $HOME
  }
  if ($expanded.StartsWith('~/') -or $expanded.StartsWith('~\')) {
    return Join-Path $HOME $expanded.Substring(2)
  }
  return $expanded
}

function Get-AbsolutePath {
  param([Parameter(Mandatory = $true)][string]$Path)

  return [System.IO.Path]::GetFullPath((Expand-HomePath $Path))
}

function Get-RelativePath {
  param(
    [Parameter(Mandatory = $true)][string]$From,
    [Parameter(Mandatory = $true)][string]$To
  )

  $fromPath = (Resolve-Path -LiteralPath $From).Path.TrimEnd(
    [char[]]@([char]'\', [char]'/')
  ) + '\'
  $toPath = [System.IO.Path]::GetFullPath($To)
  $fromUri = [System.Uri]::new("file:///$($fromPath.Replace('\', '/'))")
  $toUri = [System.Uri]::new("file:///$($toPath.Replace('\', '/'))")
  return [System.Uri]::UnescapeDataString(
    $fromUri.MakeRelativeUri($toUri).ToString()
  ).Replace('\', '/')
}

function ConvertTo-YamlQuoted {
  param([Parameter(Mandatory = $true)][string]$Value)

  return "'" + $Value.Replace("'", "''") + "'"
}

function Write-TextFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content
  )

  [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Show-DartSetupHelp {
  @'
Dart SDK was not found on PATH.

Chocolatey is available. Install Dart, reopen PowerShell, and rerun:
  choco install dart-sdk

A Flutter SDK also includes Dart when its bin directory is on PATH.
'@ | ForEach-Object { [Console]::Error.WriteLine($_) }
}

function Show-ChocolateySetupHelp {
  @'
Chocolatey was not found and Dart SDK is not available on PATH.

Install Chocolatey from https://chocolatey.org/install, reopen PowerShell, and
rerun this launcher. It will then advise the Dart installation command:
  choco install dart-sdk

If you manage Dart through another supported system, install Dart >=3.6.0 and
<4.0.0, ensure it is on PATH, and rerun this launcher.
'@ | ForEach-Object { [Console]::Error.WriteLine($_) }
}

function Get-DartVersion {
  $outputLines = @(& dart --version 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) {
    return $null
  }
  $output = [string]::Join([Environment]::NewLine, $outputLines)
  if ($output -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
    return $Matches[1]
  }
  return $null
}

function Test-DartVersion {
  param([Parameter(Mandatory = $true)][string]$Version)

  if ($Version -notmatch '^([0-9]+)\.([0-9]+)\.([0-9]+)$') {
    return $false
  }
  $major = [int]$Matches[1]
  $minor = [int]$Matches[2]
  return $major -eq $DartMinimumMajor -and $minor -ge $DartMinimumMinor
}

function Test-SupportedDart {
  if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
    return $false
  }
  $version = Get-DartVersion
  return $null -ne $version -and (Test-DartVersion $version)
}

function Ensure-Dart {
  if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
      Show-ChocolateySetupHelp
      Fail 'Install Chocolatey, then rerun the launcher to continue Dart setup.'
    }
    Show-DartSetupHelp
    Fail 'Install Dart with Chocolatey or rerun with -SkipPubGet to create an unresolved scaffold.'
  }

  $version = Get-DartVersion
  if ($null -eq $version) {
    Fail 'Could not determine the installed Dart SDK version.'
  }
  if (-not (Test-DartVersion $version)) {
    [Console]::Error.WriteLine(
      "Dart $version is incompatible; this launcher requires Dart >=3.6.0 and <4.0.0."
    )
    Fail 'Install a compatible Dart SDK, reopen PowerShell, and rerun this launcher.'
  }
}

function Test-PackageCheckout {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$ExpectedName,
    [Parameter(Mandatory = $true)][string]$Checkout
  )

  $manifest = Join-Path $Checkout 'pubspec.yaml'
  if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    Fail "$Label checkout must contain a package named ${ExpectedName}: $Checkout"
  }
  $namePattern = "^name:\s*$([regex]::Escape($ExpectedName))\s*$"
  if (-not (Select-String -LiteralPath $manifest -Pattern $namePattern -Quiet)) {
    Fail "$Label checkout must contain a package named ${ExpectedName}: $Checkout"
  }
}

function Resolve-LocalCheckout {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$ExpectedName,
    [Parameter(Mandatory = $true)][string]$Candidate
  )

  $candidatePath = Get-AbsolutePath $Candidate
  if (-not (Test-Path -LiteralPath $candidatePath -PathType Container)) {
    Fail "$Label checkout not found: $candidatePath"
  }
  $candidatePath = (Resolve-Path -LiteralPath $candidatePath).Path
  Test-PackageCheckout $Label $ExpectedName $candidatePath
  Write-Host "Using local $Label checkout: $candidatePath"
  return $candidatePath
}

function Get-PackageVersion {
  param([Parameter(Mandatory = $true)][string]$Manifest)

  foreach ($line in Get-Content -LiteralPath $Manifest) {
    if ($line -match '^\s*version:\s*(\S+)') {
      return $Matches[1]
    }
  }
  return ''
}

function Test-Templates {
  foreach ($relativePath in @(
    '.gitignore',
    'pubspec.yaml.tmpl',
    'README.md.tmpl',
    'lib/package.dart.tmpl',
    'lib/src/module.dart.tmpl',
    'lib/src/typed_module.dart.tmpl',
    'test/module_test.dart.tmpl',
    'test/typed_module_test.dart.tmpl'
  )) {
    $path = Join-Path $script:TemplateRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      Fail "Launcher bundle is incomplete; missing template: $path"
    }
  }
}

function Expand-Starter {
  if (-not (Test-Path -LiteralPath $StarterArchive -PathType Leaf)) {
    Fail "Launcher bundle is incomplete; missing starter archive: $StarterArchive"
  }
  if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
    Fail 'The launcher bundle requires tar.exe. Use Windows 10 or later, or install tar before rerunning.'
  }

  $script:TemplateWorkDirectory = Join-Path ([System.IO.Path]::GetTempPath()) (
    "rohd-create-starter-$([System.Guid]::NewGuid())"
  )
  New-Item -ItemType Directory -Force -Path $script:TemplateWorkDirectory | Out-Null
  & tar -xzf $StarterArchive -C $script:TemplateWorkDirectory
  if ($LASTEXITCODE -ne 0) {
    Fail 'Could not extract the bundled starter area.'
  }
  $script:TemplateRoot = Join-Path $script:TemplateWorkDirectory 'starter'
  Test-Templates
}

function Render-Template {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Output
  )

  $content = [System.IO.File]::ReadAllText($Source)
  $content = $content.Replace('__PACKAGE_NAME__', $PackageName)
  $content = $content.Replace('__MODULE_NAME__', $ModuleName)
  $content = $content.Replace('__MODULE_FILE__', $moduleFile)
  $content = $content.Replace('__ROHD_VERSION__', $rohdVersion)
  $content = $content.Replace('__HCL_VERSION__', $hclVersion)
  $content = $content.Replace('__VF_VERSION__', $vfVersion)
  Write-TextFile $Output $content
}

if ($Help) {
  Show-Usage
  exit 0
}

if ([string]::IsNullOrWhiteSpace($Destination)) {
  Show-Usage
  exit 2
}

$Destination = Get-AbsolutePath $Destination
if (Test-Path -LiteralPath $Destination) {
  if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
    Fail 'Destination exists and is not a directory.'
  }
  if (Get-ChildItem -LiteralPath $Destination -Force | Select-Object -First 1) {
    Fail "Destination is not empty: $Destination"
  }
}

if (-not $SkipPubGet) {
  Ensure-Dart
}
Expand-Starter

$rohdVersion = $DefaultRohdVersion
$hclVersion = $DefaultHclVersion
$vfVersion = $DefaultVfVersion
$rohdHierarchyPath = $null

if (-not [string]::IsNullOrWhiteSpace($RohdPath)) {
  $RohdPath = Resolve-LocalCheckout 'ROHD' 'rohd' $RohdPath
  $rohdHierarchyPath = Join-Path $RohdPath 'packages/rohd_hierarchy'
  Test-PackageCheckout 'ROHD' 'rohd_hierarchy' $rohdHierarchyPath
  $rohdVersion = Get-PackageVersion (Join-Path $RohdPath 'pubspec.yaml')
}
if (-not [string]::IsNullOrWhiteSpace($HclPath)) {
  $HclPath = Resolve-LocalCheckout 'ROHD-HCL' 'rohd_hcl' $HclPath
  $hclVersion = Get-PackageVersion (Join-Path $HclPath 'pubspec.yaml')
}
if (-not [string]::IsNullOrWhiteSpace($VfPath)) {
  $VfPath = Resolve-LocalCheckout 'ROHD-VF' 'rohd_vf' $VfPath
  $vfVersion = Get-PackageVersion (Join-Path $VfPath 'pubspec.yaml')
}
if ([string]::IsNullOrWhiteSpace($rohdVersion) -or
    [string]::IsNullOrWhiteSpace($hclVersion) -or
    [string]::IsNullOrWhiteSpace($vfVersion)) {
  Fail 'Could not read a local framework package version.'
}

if ([string]::IsNullOrWhiteSpace($PackageName)) {
  $PackageName = Split-Path -Leaf $Destination
  $PackageName = $PackageName.ToLowerInvariant() -replace '-', '_'
  $PackageName = $PackageName -replace '[^a-z0-9_]+', '_'
  $PackageName = $PackageName -replace '_+', '_'
  $PackageName = $PackageName.Trim('_')
  if ($PackageName -notmatch '^[a-z]') {
    $PackageName = "rohd_$PackageName"
  }
}
if ($PackageName -notmatch '^[a-z][a-z0-9_]*$') {
  Fail "Invalid Dart package name: $PackageName"
}
if ($ModuleName -notmatch '^[A-Z][A-Za-z0-9]*$') {
  Fail 'Module name must be a PascalCase Dart identifier.'
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
$moduleFile = [regex]::Replace(
  $ModuleName,
  '([a-z0-9])([A-Z])',
  '$1_$2'
).ToLowerInvariant()
if (-not [string]::IsNullOrWhiteSpace($RohdPath)) {
  $rohdRelative = Get-RelativePath $Destination $RohdPath
  $hierarchyRelative = Get-RelativePath $Destination $rohdHierarchyPath
}
if (-not [string]::IsNullOrWhiteSpace($HclPath)) {
  $hclRelative = Get-RelativePath $Destination $HclPath
}
if (-not [string]::IsNullOrWhiteSpace($VfPath)) {
  $vfRelative = Get-RelativePath $Destination $VfPath
}

New-Item -ItemType Directory -Force -Path @(
  (Join-Path $Destination 'lib/src'),
  (Join-Path $Destination 'test')
) | Out-Null
Copy-Item -LiteralPath (Join-Path $script:TemplateRoot '.gitignore') -Destination (
  Join-Path $Destination '.gitignore'
)
Render-Template (Join-Path $script:TemplateRoot 'pubspec.yaml.tmpl') (
  Join-Path $Destination 'pubspec.yaml'
)
Render-Template (Join-Path $script:TemplateRoot 'lib/package.dart.tmpl') (
  Join-Path $Destination "lib/$PackageName.dart"
)
Render-Template (Join-Path $script:TemplateRoot 'lib/src/module.dart.tmpl') (
  Join-Path $Destination "lib/src/$moduleFile.dart"
)
Render-Template (Join-Path $script:TemplateRoot 'lib/src/typed_module.dart.tmpl') (
  Join-Path $Destination "lib/src/${moduleFile}_typed.dart"
)
Render-Template (Join-Path $script:TemplateRoot 'test/module_test.dart.tmpl') (
  Join-Path $Destination "test/${moduleFile}_test.dart"
)
Render-Template (Join-Path $script:TemplateRoot 'test/typed_module_test.dart.tmpl') (
  Join-Path $Destination "test/${moduleFile}_typed_test.dart"
)
Render-Template (Join-Path $script:TemplateRoot 'README.md.tmpl') (
  Join-Path $Destination 'README.md'
)

if ((-not [string]::IsNullOrWhiteSpace($RohdPath)) -or
    (-not [string]::IsNullOrWhiteSpace($HclPath)) -or
    (-not [string]::IsNullOrWhiteSpace($VfPath))) {
  $pubspecPath = Join-Path $Destination 'pubspec.yaml'
  $pubspec = [System.IO.File]::ReadAllText($pubspecPath)
  $pubspec += "`ndependency_overrides:`n"
  if (-not [string]::IsNullOrWhiteSpace($RohdPath)) {
    $pubspec += @"
  rohd:
    path: $(ConvertTo-YamlQuoted $rohdRelative)
  rohd_hierarchy:
    path: $(ConvertTo-YamlQuoted $hierarchyRelative)
"@
  }
  if (-not [string]::IsNullOrWhiteSpace($HclPath)) {
    $pubspec += @"
  rohd_hcl:
    path: $(ConvertTo-YamlQuoted $hclRelative)
"@
  }
  if (-not [string]::IsNullOrWhiteSpace($VfPath)) {
    $pubspec += @"
  rohd_vf:
    path: $(ConvertTo-YamlQuoted $vfRelative)
"@
  }
  Write-TextFile $pubspecPath $pubspec
}

if (-not $SkipPubGet) {
  Write-Host "Resolving Dart dependencies in $Destination"
  Push-Location $Destination
  try {
    & dart pub get
    if ($LASTEXITCODE -ne 0) {
      Fail 'Dart dependency resolution failed. The generated package remains available for inspection.'
    }
  } finally {
    Pop-Location
  }
}

if (Test-SupportedDart) {
  Push-Location $Destination
  try {
    & dart format lib test
    if ($LASTEXITCODE -ne 0) {
      Fail 'Dart formatting failed.'
    }
  } finally {
    Pop-Location
  }
} elseif (Get-Command dart -ErrorAction SilentlyContinue) {
  Write-Warning 'Installed Dart is incompatible; run dart format lib test after installing Dart >=3.6.0 and <4.0.0.'
} else {
  Write-Warning 'Dart was not found; run dart format lib test after creation.'
}

Write-Host "Created ROHD development area: $Destination"
Write-Host "Package: $PackageName"
Write-Host "Module: $ModuleName"
if (-not [string]::IsNullOrWhiteSpace($RohdPath)) {
  Write-Host "ROHD local override: $RohdPath"
} else {
  Write-Host "ROHD hosted constraint: ^$rohdVersion"
}
if (-not [string]::IsNullOrWhiteSpace($HclPath)) {
  Write-Host "ROHD-HCL local override: $HclPath"
} else {
  Write-Host "ROHD-HCL hosted constraint: ^$hclVersion"
}
if (-not [string]::IsNullOrWhiteSpace($VfPath)) {
  Write-Host "ROHD-VF local override: $VfPath"
} else {
  Write-Host "ROHD-VF hosted constraint: ^$vfVersion"
}
if ($SkipPubGet) {
  Write-Host "Dependencies were not resolved. Run: Set-Location '$Destination'; dart pub get"
} else {
  Write-Host "Next: Set-Location '$Destination'; dart test"
}
Cleanup-Starter
