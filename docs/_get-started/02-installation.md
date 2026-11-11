---
title: "Setup & Install"
permalink: /get-started/setup/
excerpt: "Instructions for installing the theme for new and existing Jekyll based sites."
last_modified_at: 2026-10-25
toc: true
---

## Getting started

Follow the instruction at [https://dart.dev/get-dart](https://dart.dev/get-dart) to install `dart` in your environment.

### Create a starter package

You do not need to clone the ROHD source repository to create and test a new
ROHD module. The launchers below download one small platform bundle, create a
normal Dart package in the directory you choose, and resolve published ROHD
packages from pub.dev.

<p>
  <a href="{{ site.baseurl }}/assets/downloads/rohd_create_linux.zip" class="btn btn--primary btn--large" download="rohd_create_linux.zip"><i class="fab fa-linux"></i> Download Linux / WSL bundle</a>
  <a href="{{ site.baseurl }}/assets/downloads/rohd_create_windows.zip" class="btn btn--info btn--large" download="rohd_create_windows.zip"><i class="fab fa-windows"></i> Download Windows bundle</a>
</p>

On Linux or WSL, extract the bundle, then create and test a package:

```sh
unzip rohd_create_linux.zip
cd rohd_create
chmod +x rohd_create.sh
./rohd_create.sh ~/work/my-first-module --module-name MyFirstModule
cd ~/work/my-first-module
dart test
```

On Windows PowerShell:

```powershell
Expand-Archive .\rohd_create_windows.zip
Set-Location .\rohd_create
powershell -ExecutionPolicy Bypass -File .\rohd_create.ps1 `
  C:\work\my-first-module -ModuleName MyFirstModule
Set-Location C:\work\my-first-module
dart test
```

The Linux/WSL launcher checks for a compatible Dart SDK (>=3.6.0 and <4.0.0)
and explains how to install or update it if needed. On Windows, the launcher
first checks whether Chocolatey is available when Dart is missing: it directs
you to Chocolatey setup if needed, then directs Chocolatey users to
`choco install dart-sdk`. Neither launcher downloads or requires an ROHD
checkout. To develop against unpublished ROHD, ROHD-HCL, or ROHD-VF source,
use their documented local-path override options instead.

### Set up a package manually

Once you have Dart installed, if you don't already have a project, you can create one using `dart create`: <https://dart.dev/tools/dart-tool>

Then add ROHD as a dependency to your pubspec.yaml file.  ROHD is [registered](https://pub.dev/packages/rohd) on pub.dev.  The easiest way to add ROHD as a dependency is following the instructions here <https://pub.dev/packages/rohd/install>.

Now you can import it in your project using:

```dart
import 'package:rohd/rohd.dart';
```

There are complete API docs available at <https://intel.github.io/rohd/rohd/rohd-library.html>.

If you need some help, you can join the [Discord server](https://discord.com/invite/jubxF84yGw) or visit our [Discussions](https://github.com/intel/rohd/discussions) page.  These are friendly places where you can ask questions, share ideas, or just discuss openly!  You could also head to [StackOverflow.com](https://stackoverflow.com/) (use the tag `rohd`) to ask questions or look for answers.

You also may be interested to join the [ROHD Forum](https://intel.github.io/rohd-website/forum/rohd-forum/) periodic meetings with other users and developers in the ROHD community.  The meetings are open to anyone interested!

Be sure to note the minimum Dart version required for ROHD specified in pubspec.yaml (at least 2.18.0).

## Package Managers for Hardware

In the Dart ecosystem, you can use a package manager to define all package dependencies.  A package manager allows you to define constrained subsets of versions of all your *direct* dependencies, and then the tool will solve for a coherent set of all (direct and indirect) dependencies required to build your project.  There's no need to manually figure out tool versions, build flags and options, environment setup, etc. because it is all guaranteed to work.  Integration of other packages (whether a tool or a hardware IP) become as simple as an `import` statement.  Compare that to SystemVerilog IP integration!

Read more about package managers here: <https://en.wikipedia.org/wiki/Package_manager>

Take a look at Dart's package manager, pub.dev, here: <https://pub.dev>
