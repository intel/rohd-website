---
title: "VS Code as a ROHD Design Cockpit"
permalink: /blog/rohd-design-cockpit-in-vs-code/
last_modified_at: 2026-10-23
author: "Desmond A. Kirkpatrick"
classes: [wide, narrow-sidebar]
---

Hardware design is most productive when structure, behavior, and generator source
are connected instead of spread across unrelated tools. Microsoft Visual Studio
Code® (VS Code) is already an excellent environment for Dart™: the Dart analyzer
provides editor diagnostics, navigation, completion, and debugging support. ROHD
is built on Dart, so ROHD designs benefit immediately from that language support
while adding hardware-specific simulation, elaboration, and visualization tools.

With the [ROHD Schematic Viewer]({{ site.baseurl }}/blog/announcing-rohd-schematic-viewer/)
and [ROHD Wave Viewer]({{ site.baseurl }}/blog/rohd-wave-viewer-standalone/)
extensions installed, VS Code becomes a **ROHD Design Cockpit**: a coordinated
workspace for developing a design, inspecting simulation results, exploring
generated RTL, and returning to the ROHD source that created a signal.

## How to Get It

Install the
[ROHD extension](https://marketplace.visualstudio.com/items?itemName=intel-corporation.rohd)
from the Visual Studio Marketplace. Published as `intel-corporation.rohd`, it
includes an extension pack that installs the
[ROHD Schematic Viewer](https://marketplace.visualstudio.com/items?itemName=intel-corporation.rohd-schematic-viewer)
and [ROHD Wave Viewer](https://marketplace.visualstudio.com/items?itemName=intel-corporation.rohd-wave-viewer),
so the coordinated views are ready together.

The extension also provides basic ROHD editor support, including syntax-expansion
snippets. It is the foundation for deeper ROHD-aware editor support, including the
Dart analyzer integration described below.

## Build, Simulate, and Inspect

ROHD's built-in simulator fits naturally into the Dart development experience.
From VS Code, set breakpoints in a ROHD test, step through the simulation, and
inspect or print signal values while the test runs. The same test can record a
waveform for closer inspection after the fact.

For a module such as a `FilterBank`, constructing the module and completing its
`build()` step is analogous to elaborating a conventional HDL design: ROHD
creates the module hierarchy and connections that represent the hardware. A test
then drives the elaborated design, advances simulation time, checks expected
values, and can emit the waveform trace used by the Wave Viewer. From that same
elaborated design, ROHD can generate a netlist for the Schematic Viewer. One test
and one design description can therefore lead to the simulation values, waveform,
and structural view needed to investigate an issue.

## Generate the Views and Source Artifacts

Start source tracing before constructing the design, then build the module before
asking ROHD to simulate it or generate outputs. A simple test can record a VCD
trace with `dut.dumpWaves()`; a `DebugSession` can instead provide live waveform
data and registered services to the ROHD tools. The viewer extensions use these
artifacts from the elaborated design:

- **Netlist**: create a `NetlistService` with
  `NetlistSynthesizerConfiguration(trace: true)` to generate the Yosys JSON
  consumed by the Schematic Viewer. The tracing option adds ROHD source
  information to the netlist.
- **Waveform**: record the simulation as VCD, FST, or GHW and open it in the Wave
  Viewer. A live `DebugSession` supplies waveform updates while the simulation is
  running.
- Advanced Usage:
  - **Generated RTL**: use `SystemVerilogService` to emit SystemVerilog® files.
    Add a `SystemCService` to emit SystemC® files as well. These generated
    outputs are optional, but make it possible to inspect the emitted RTL in the
    editor.
  - **FLC sidecar for generated RTL**: when emitting SystemVerilog or SystemC,
    create a `TraceService` and call `write()` to produce the File-Line-Column
    (FLC) dictionary JSON sidecar. The dictionary associates a generated signal
    or module instance with its Dart construction site and its location in the
    emitted SystemVerilog and/or SystemC files.

A traced netlist carries its own compact ROHD source attributes, so schematic
navigation back to ROHD does not need generated RTL or an FLC sidecar. The FLC
dictionary is needed only when generated SystemVerilog or SystemC should also
participate in source navigation. A test can therefore produce just a netlist or
waveform, add generated RTL and its mapping when required, or create all of the
artifacts together.

### Simplest case: traced netlist and ROHD source

For the simplest schematic-to-ROHD-source workflow, a `FilterBank` test needs
only a traced netlist. The `FilterBank` example is available in the ROHD
repository; its constructor and test stimulus will vary by design, while the
source-tracing and netlist setup is reusable:

```dart
import 'dart:io';

import 'package:rohd/rohd.dart';

Future<void> writeFilterBankNetlist() async {
  SourceTracer.activate();

  // Create FilterBank with the inputs used by this test.
  final filterBank = createFilterBankForTest();
  await filterBank.build();

  final netlist = NetlistService(
    filterBank,
    configuration: const NetlistSynthesizerConfiguration(trace: true),
    packageRoot: Directory.current.path,
  );
  await File('build/filter_bank.json').writeAsString(netlist.toJson());
  SourceTracer.clear();
}
```

The resulting Yosys JSON netlist contains `rohd.src_trace` attributes that
connect the schematic's signals and modules to their ROHD construction sites.
Open that netlist in the Schematic Viewer and choose **Go to ROHD Source** for
source cross-probing; no external FLC sidecar or generated HDL is required.

### Add an FLC sidecar for generated-language navigation

When the workflow also needs SystemVerilog or SystemC source navigation, create
the generated-code services and attach them to `TraceService`. This example
extends the same traced-and-built `filterBank` before `SourceTracer.clear()`:

```dart
final sv = SystemVerilogService(
  filterBank,
  multiFile: true,
  register: false,
);
final sc = SystemCService(filterBank, multiFile: true, register: false);
final trace = TraceService(
  filterBank,
  svService: sv,
  scService: sc,
  packageRoot: Directory.current.path,
  register: false,
  svOutputMode: SvOutputMode.perModule,
  scOutputMode: ScOutputMode.perModule,
);

sv.writeFiles('build/generated');
sc.writeFiles('build/generated');
trace.write('build/generated');
```

This produces generated SystemVerilog and SystemC plus one FLC dictionary that
associates both generated languages with the ROHD source. Omit the
`SystemCService` when only SystemVerilog output is wanted. The Schematic Viewer
or Wave Viewer can use the FLC dictionary to navigate to the generated-language
source as well as the ROHD source.

## See the Design's Structure

The ROHD Schematic Viewer renders a netlist generated from a ROHD design as an
interactive schematic. Pan, zoom, and expand hierarchy only where it is needed;
then select ports or wires to follow the connections that matter. Search by wire
name or hierarchy path, and use the viewer's ROHD type awareness to inspect
structured signals and arrays meaningfully. The image below shows the Schematic
Viewer embedded in VS Code beside the ROHD project and generated netlist. The
[Schematic Viewer announcement]({{ site.baseurl }}/blog/announcing-rohd-schematic-viewer/)
also covers its standalone web application.

{:refdef: style="text-align: center;"}
![ROHD Schematic Viewer embedded in VS Code beside the ROHD project and generated netlist]({{ site.baseurl }}/assets/images/rohd-design-cockpit-in-vs-code/VSCodeSchematic.png){:width="1000px"}
{: refdef}

The extension opens a Yosys JSON netlist alongside the design's source. ROHD's
`NetlistService` can generate that netlist, and
`NetlistSynthesizerConfiguration(trace: true)` preserves File/Line/Column
locations for generated signals. With source tracing enabled, choose **Go to ROHD
Source** on a schematic signal to cross-probe directly to the Dart code that
generated it. When more than one source location applies, VS Code presents the
relevant frame to choose from.
If SystemVerilog or SystemC output and its FLC mapping are available, the
Schematic Viewer can also navigate to the corresponding generated source.

{:refdef: style="text-align: center;"}
![ROHD Schematic Viewer context menu showing cross-probing to ROHD source and generated SystemVerilog source]({{ site.baseurl }}/assets/images/rohd-design-cockpit-in-vs-code/SchematicCrossProbe.png){:width="1000px"}
{: refdef}

## See What the Design Did

The ROHD Wave Viewer brings the same signal hierarchy into a waveform workspace.
Open VCD, FST, or GHW traces, filter the hierarchy, select the signals to monitor,
and use markers, zoom, value formats, and edge navigation to investigate the
cycles where behavior changes. Signal lists and full viewer sessions can be saved
and restored, making it easy to return to a useful debug setup. The image below
shows the Wave Viewer embedded in VS Code alongside the ROHD project and the
waveform file it opened. The
[Wave Viewer post]({{ site.baseurl }}/blog/rohd-wave-viewer-standalone/) describes
the separate browser-based viewer.

{:refdef: style="text-align: center;"}
![ROHD Wave Viewer embedded in VS Code beside the ROHD project and opened waveform file]({{ site.baseurl }}/assets/images/rohd-design-cockpit-in-vs-code/VSCodeWaveViewer.png){:width="1000px"}
{: refdef}

## Cross-Probe Between Views

The two extensions turn the editor into more than two independent viewers. Select
a signal in the schematic and send it to the Wave Viewer to find the matching
hierarchy path and add its recorded waveform. Select a waveform signal and send
it back to locate the corresponding connection in the rendered RTL. The linked
views keep structural and behavioral investigation in the same workflow.

{:refdef: style="text-align: center;"}
![ROHD Wave Viewer sending the selected carryOut_flopped signal to the linked Schematic Viewer]({{ site.baseurl }}/assets/images/rohd-design-cockpit-in-vs-code/WaveformSend.png){:width="1000px"}
{: refdef}

Not every internal net is recorded in a waveform. In that case, the Schematic
Viewer can send a connected module port instead, so the Wave Viewer can still show
a useful driving or receiving signal. The result is a quick route from a waveform
transition, to its RTL connection, to the ROHD source that describes the design.
When matching generated SystemVerilog or SystemC artifacts are available, either
viewer can also cross-probe to that generated source.

## Build a Better ROHD Workflow

The extensions are designed to complement the rest of the ROHD tooling rather than
replace the normal edit, simulate, and test loop. Use the schematic to understand
the generated design, the waveform viewer to understand its behavior over time,
and source cross-probing to make a precise code change without losing the hardware
context. The Dart debugger and ROHD simulator provide the first interactive pass;
the generated waveform and netlist provide the linked behavioral and structural
views when a question needs more context.

## What's Ahead

We are extending the ROHD extension with a Dart analyzer plugin that provides
ROHD-specific static checks directly in VS Code. It will build on Dart's existing
analysis experience to surface hardware-design issues earlier, before simulation,
while keeping design, behavior, and source feedback in one place. The
[ROHD hierarchy lints](https://github.com/intel/rohd-hierarchy-lints) project
contains example rules that illustrate the kind of ROHD-aware guidance we are
developing.

## Get Involved

Try the extensions from the Marketplace and let us know what would make your ROHD
Design Cockpit more effective. Join the
[ROHD Discord server](https://discord.com/invite/jubxF84yGw) to share feedback,
or file issues with the
[ROHD Schematic Viewer](https://github.com/intel/rohd-schematic-viewer/issues) or
[ROHD Wave Viewer](https://github.com/intel/rohd-wave-viewer/issues) projects.
