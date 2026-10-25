# Copyright (C) 2026 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#
# rohd_create_test.ps1
# Tests the standalone PowerShell ROHD development-area bootstrapper.
#
# 2026 October 25
# Author: Desmond A. Kirkpatrick <desmond.a.kirkpatrick@intel.com>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Contains {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Expected
  )

  $content = [System.IO.File]::ReadAllText($Path)
  if (-not $content.Contains($Expected)) {
    throw "Expected '$Path' to contain '$Expected'."
  }
}

function Assert-NotContains {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Unexpected
  )

  $content = [System.IO.File]::ReadAllText($Path)
  if ($content.Contains($Unexpected)) {
    throw "Expected '$Path' not to contain '$Unexpected'."
  }
}

function Write-Pubspec {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Version
  )

@"
name: $Name
version: $Version
"@ | Set-Content -LiteralPath $Path -Encoding utf8
}

$websiteRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$bundleBuilder = Join-Path $websiteRoot 'tool/build_rohd_create_bundles.py'
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) (
  "rohd-development-area-$([System.Guid]::NewGuid())"
)

try {
  $downloadDirectory = Join-Path $fixture 'download'
  $bundleDirectory = Join-Path $fixture 'bundles'
  $generator = Join-Path $downloadDirectory 'rohd_create/rohd_create.ps1'
  $binDirectory = Join-Path $fixture 'bin'
  $rohd = Join-Path $fixture 'rohd'
  $hcl = Join-Path $fixture 'rohd-hcl'
  $vf = Join-Path $fixture 'rohd-vf'
  $destination = Join-Path $fixture 'development area'
  $overrideDestination = Join-Path $fixture 'override area'
  $formattedDestination = Join-Path $fixture 'formatted area'
  $dartCallLog = Join-Path $fixture 'dart_calls'

  New-Item -ItemType Directory -Force -Path @(
    $downloadDirectory,
    $binDirectory,
    (Join-Path $rohd 'packages/rohd_hierarchy'),
    $hcl,
    $vf
  ) | Out-Null
  & python $bundleBuilder $bundleDirectory
  if ($LASTEXITCODE -ne 0) {
    throw 'ROHD Create bundle build failed.'
  }
  Expand-Archive (
    Join-Path $bundleDirectory 'rohd_create_windows.zip'
  ) -DestinationPath $downloadDirectory

@'
@echo off
echo Git must not run for a hosted development area. 1>&2
exit /b 99
'@ | Set-Content -LiteralPath (Join-Path $binDirectory 'git.cmd') -Encoding ascii

  Write-Pubspec (Join-Path $rohd 'pubspec.yaml') 'rohd' '0.6.11'
  Write-Pubspec (
    Join-Path $rohd 'packages/rohd_hierarchy/pubspec.yaml'
  ) 'rohd_hierarchy' '0.1.1'
  Write-Pubspec (Join-Path $hcl 'pubspec.yaml') 'rohd_hcl' '0.3.0'
  Write-Pubspec (Join-Path $vf 'pubspec.yaml') 'rohd_vf' '0.6.0'

  $help = (& $generator -Help) -join "`n"
  if (-not $help.Contains('OUTPUT_DIRECTORY is the new package directory.') -or
      -not $help.Contains('The launcher must remain beside its bundled starter.tar.gz archive.') -or
      -not $help.Contains('the generated package resolves compatible published versions of ROHD,') -or
      -not $help.Contains('ROHD-HCL, and ROHD-VF from pub.dev.') -or
      -not $help.Contains('-RohdPath PATH') -or
      -not $help.Contains('-VfPath PATH') -or
      -not $help.Contains('-SkipPubGet') -or
      $help.Contains('-Workspace')) {
    throw 'PowerShell bootstrapper help is incomplete.'
  }

  $originalPath = $env:Path
  $noDartStatus = $null
  try {
    $env:Path = "$binDirectory;$env:SystemRoot\System32"
    $noDartOutput = & (Join-Path $PSHOME 'pwsh.exe') `
      -NoProfile `
      -ExecutionPolicy Bypass `
      -File $generator `
      (Join-Path $fixture 'no-dart') 2>&1
    $noDartStatus = $LASTEXITCODE
  } finally {
    $env:Path = $originalPath
  }
  if ($noDartStatus -eq 0) {
    throw 'Expected the default bootstrap to require Dart.'
  }
  if ((($noDartOutput | Out-String) -notmatch 'Chocolatey was not found') -or
      (($noDartOutput | Out-String) -notmatch 'https://chocolatey.org/install')) {
    throw 'PowerShell bootstrapper did not provide Chocolatey setup guidance.'
  }

@'
@echo off
exit /b 0
'@ | Set-Content -LiteralPath (Join-Path $binDirectory 'choco.cmd') -Encoding ascii

  try {
    $env:Path = "$binDirectory;$env:SystemRoot\System32"
    $dartMissingOutput = & (Join-Path $PSHOME 'pwsh.exe') `
      -NoProfile `
      -ExecutionPolicy Bypass `
      -File $generator `
      (Join-Path $fixture 'dart-missing') 2>&1
    $dartMissingStatus = $LASTEXITCODE
  } finally {
    $env:Path = $originalPath
  }
  if ($dartMissingStatus -eq 0) {
    throw 'Expected the bootstrap to require Dart after Chocolatey is available.'
  }
  if ((($dartMissingOutput | Out-String) -notmatch 'Dart SDK was not found on PATH') -or
      (($dartMissingOutput | Out-String) -notmatch 'choco install dart-sdk')) {
    throw 'PowerShell bootstrapper did not provide Dart installation guidance.'
  }

@'
@echo off
if not "%DART_CALL_LOG%"=="" echo %~1>>"%DART_CALL_LOG%"
if /I "%1"=="--version" (
  echo Dart SDK version: %FAKE_DART_VERSION% (stable) on "Windows" 1>&2
  exit /b 0
)
if /I "%1"=="format" exit /b 0
if /I "%1"=="pub" exit /b 0
exit /b 0
'@ | Set-Content -LiteralPath (Join-Path $binDirectory 'dart.cmd') -Encoding ascii

  try {
    $env:FAKE_DART_VERSION = '3.5.0'
    $env:Path = "$binDirectory;$env:SystemRoot\System32"
    $incompatibleOutput = & (Join-Path $PSHOME 'pwsh.exe') `
      -NoProfile `
      -ExecutionPolicy Bypass `
      -File $generator `
      (Join-Path $fixture 'incompatible-dart') 2>&1
    $incompatibleStatus = $LASTEXITCODE
  } finally {
    $env:Path = $originalPath
    Remove-Item Env:FAKE_DART_VERSION -ErrorAction SilentlyContinue
  }
  if ($incompatibleStatus -eq 0) {
    throw 'Expected an incompatible Dart SDK to be rejected.'
  }
  if ((($incompatibleOutput | Out-String) -notmatch 'Dart 3.5.0 is incompatible') -or
      (($incompatibleOutput | Out-String) -notmatch 'requires Dart >=3.6.0 and <4.0.0')) {
    throw 'PowerShell bootstrapper did not report the required Dart range.'
  }

  try {
    $env:FAKE_DART_VERSION = '3.6.0'
    $env:Path = "$binDirectory;$env:SystemRoot\System32"
    $global:LASTEXITCODE = 0
    & $generator $destination `
      -PackageName starter_ports `
      -ModuleName StarterPorts `
      -SkipPubGet
    if ($LASTEXITCODE -ne 0) {
      throw 'Hosted PowerShell bootstrapper invocation failed.'
    }
  } finally {
    $env:Path = $originalPath
    Remove-Item Env:FAKE_DART_VERSION -ErrorAction SilentlyContinue
  }

  $originalDartCallLog = $env:DART_CALL_LOG
  try {
    $env:FAKE_DART_VERSION = '3.6.0'
    $env:DART_CALL_LOG = $dartCallLog
    $env:Path = "$binDirectory;$env:SystemRoot\System32"
    $global:LASTEXITCODE = 0
    & $generator $formattedDestination `
      -PackageName formatted_dart `
      -ModuleName FormattedDart
    if ($LASTEXITCODE -ne 0) {
      throw 'Hosted PowerShell bootstrapper formatting invocation failed.'
    }
  } finally {
    $env:Path = $originalPath
    Remove-Item Env:FAKE_DART_VERSION -ErrorAction SilentlyContinue
    if ($null -eq $originalDartCallLog) {
      Remove-Item Env:DART_CALL_LOG -ErrorAction SilentlyContinue
    } else {
      $env:DART_CALL_LOG = $originalDartCallLog
    }
  }
  $dartCalls = @(Get-Content -LiteralPath $dartCallLog)
  $pubIndex = [Array]::IndexOf($dartCalls, 'pub')
  $formatIndex = [Array]::IndexOf($dartCalls, 'format')
  if ($pubIndex -lt 0 -or $formatIndex -lt 0 -or $pubIndex -ge $formatIndex) {
    throw 'The launcher must resolve Pub dependencies before formatting source.'
  }

  $pubspec = Join-Path $destination 'pubspec.yaml'
  $module = Join-Path $destination 'lib/src/starter_ports.dart'
  $typedModule = Join-Path $destination 'lib/src/starter_ports_typed.dart'
  $test = Join-Path $destination 'test/starter_ports_test.dart'
  $typedTest = Join-Path $destination 'test/starter_ports_typed_test.dart'
  $readme = Join-Path $destination 'README.md'

  Assert-Contains $pubspec 'name: starter_ports'
  Assert-Contains $pubspec 'rohd: ^0.6.11'
  Assert-Contains $pubspec 'rohd_hcl: ^0.2.1'
  Assert-Contains $pubspec 'rohd_vf: ^0.6.0'
  Assert-NotContains $pubspec 'dependency_overrides:'
  if (Test-Path -LiteralPath (Join-Path $destination '.rohd-development')) {
    throw 'Hosted PowerShell bootstrapper unexpectedly created a clone workspace.'
  }
  Assert-Contains (Join-Path $destination 'lib/starter_ports.dart') "export 'src/starter_ports_typed.dart';"
  Assert-Contains $module "final invertPin = tryInput('invert');"
  Assert-Contains $module "dataIn = addInput('dataIn', dataIn);"
  Assert-Contains $module 'Combinational(['
  Assert-Contains $module 'When the optional `invert` input is absent'
  Assert-Contains $test 'StarterPorts passes through without an invert input'
  Assert-Contains $test 'StarterPorts conditionally inverts with an invert input'
  Assert-Contains $test "dut.tryInput('invert')"
  Assert-Contains $test 'WaveDumper(dut, outputPath: waveformPath);'
  Assert-Contains $test "const waveformPath = 'tmp_test/starter_ports_conditional.vcd';"
  Assert-Contains (Join-Path $destination '.gitignore') 'tmp_test/'
  Assert-Contains $typedModule 'class StarterPortsTyped extends Module'
  Assert-Contains $typedModule 'LogicArray get arrayOut'
  Assert-Contains $typedModule 'class _StarterPortsTypedPortInverter extends Module'
  Assert-Contains $typedModule 'addInterfacePorts('
  Assert-Contains $typedModule 'final arrayResult = LogicArray('
  Assert-Contains $typedModule 'arrayOut.elements[index] <= arrayResult.elements[index];'
  Assert-Contains $typedModule 'Combinational(['
  Assert-Contains $typedModule 'final arrayIn = addInputArray('
  Assert-Contains $typedModule 'dimensions: const [2],'
  Assert-Contains $typedModule 'elementWidth: 4,'
  Assert-Contains $typedModule 'numUnpackedDimensions: 1,'
  Assert-Contains $typedModule 'arrayOut.elements[index] <= child.arrayOut.elements[index];'
  Assert-Contains $typedTest 'StarterPortsTyped conditionally processes typed ports'
  Assert-Contains $typedTest 'input logic [3:0] arrayIn [1:0]'
  Assert-Contains $typedTest 'WaveDumper(dut, outputPath: waveformPath);'
  Assert-Contains $typedTest "const waveformPath = 'tmp_test/starter_ports_typed.vcd';"
  Assert-Contains $readme 'ROHD hardware skill'
  $skillLinkCount = [regex]::Matches(
    [System.IO.File]::ReadAllText($readme),
    'https://github\.com/intel/rohd/blob/main/\.github/skills/'
  ).Count
  if ($skillLinkCount -ne 1) {
    throw 'Generated README must contain exactly one ROHD skill link.'
  }
  Assert-Contains $typedTest 'dut.generateSynth()'
  Assert-Contains $typedTest 'unawaited(Simulator.run());'
  Assert-Contains $typedTest 'await clk.nextNegedge;'
  Assert-Contains $typedTest 'structureIn.flag.inject(0);'
  Assert-Contains $typedTest 'control.signalIn.inject(0);'
  Assert-Contains $typedTest 'Simulator.registerAction(Simulator.time + 1, () {'
  Assert-Contains $typedTest 'invert.put(0);'
  Assert-Contains $typedTest "contains(r'`$enddefinitions')"
  foreach ($generated in @($module, $typedModule, $test, $typedTest)) {
    Assert-NotContains $generated 'Copyright'
    Assert-NotContains $generated 'SPDX-License-Identifier'
    Assert-NotContains $generated 'Author:'
  }

  try {
    $env:FAKE_DART_VERSION = '3.6.0'
    $env:Path = "$binDirectory;$env:SystemRoot\System32"
    $global:LASTEXITCODE = 0
    & $generator $overrideDestination `
      -PackageName override_ports `
      -ModuleName OverridePorts `
      -RohdPath $rohd `
      -HclPath $hcl `
      -VfPath $vf `
      -SkipPubGet
    if ($LASTEXITCODE -ne 0) {
      throw 'Path-override PowerShell bootstrapper invocation failed.'
    }
  } finally {
    $env:Path = $originalPath
    Remove-Item Env:FAKE_DART_VERSION -ErrorAction SilentlyContinue
  }

  $overridePubspec = Join-Path $overrideDestination 'pubspec.yaml'
  Assert-Contains $overridePubspec 'rohd_hcl: ^0.3.0'
  Assert-Contains $overridePubspec 'dependency_overrides:'
  Assert-Contains $overridePubspec "path: '../rohd'"
  Assert-Contains $overridePubspec "path: '../rohd-hcl'"
  Assert-Contains $overridePubspec "path: '../rohd-vf'"
  Assert-Contains $overridePubspec "path: '../rohd/packages/rohd_hierarchy'"

  Write-Output 'Standalone PowerShell ROHD development-area bootstrapper checks passed.'
} finally {
  if (Test-Path -LiteralPath $fixture) {
    Remove-Item -LiteralPath $fixture -Recurse -Force
  }
}
