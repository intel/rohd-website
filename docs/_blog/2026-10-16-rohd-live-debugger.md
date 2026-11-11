---
title: "The ROHD Live Debugger: An Integrated, Interactive View of Your ROHD Design and Simulation"
permalink: /blog/rohd-live-debugger/
last_modified_at: 2026-10-16
author: "Desmond A. Kirkpatrick"
classes:
  - wide
  - debugger-narrow-sidebar
---

In early 2024 we [introduced the ROHD DevTools extension]({{ site.baseurl }}/blog/announcing-rohd-devtool-extension/) as a Flutter™-based debugger that could show the ROHD module hierarchy and live signal values while a design was paused in a breakpoint. Since then, it has grown into the **ROHD Live Debugger**, a web application which lets you attach to a large running design, traverse and inspect the design and its live simulation values.

- Attach to any one of multiple live ROHD sessions in Visual Studio Code® (VS Code)
- Navigate to any level of hierarchy:
  - Display its module subhierarchy
  - Select waveform signals to display
  - Display and explore an RTL schematic of that level
- Pause and resume display tracking while a simulation continues to run
- Cross-probe by sending a signal selection to another pane:
  - Add waveforms from a schematic selection
  - Zoom to a schematic signal by sending a waveform selection
  - Send a signal to both panes from a details pane or an integrated shell

## Scale to Large Designs using Occurrence Handles

One way to think of the **ROHD Live Debugger** is as remote attached browser portal to a large design living inside a ROHD simulator controlled by VS Code. It has a core infrastructure intended to deal with debugging detailed signals within a very large and deep hierarchical scope.

The debugger communicates with the remote ROHD session through **occurrence handles**: compact, portable references to signals and cells rather than cumbersome hierarchical strings. A handle carries a signal's canonical path, leaf name, width, and stable address as a single lightweight reference. This keeps waveform and design-connectivity transfers efficient as designs grow, without repeatedly serializing and resolving large hierarchy paths.

Below is a walkthrough of a typical debug session using a simple pipelined floating-point adder design as an example.

## Start a Debug Session

The **ROHD Live Debugger** attaches to a Dart™ Virtual Machine (VM) in running your ROHD simulation in VS Code by connecting to the Dart Tooling Daemon (DTD). It does this either automatically when opened from Flutter DevTools, or standalone by discovering running VMs through a DTD URI or pasting a VM service URI directly. Here we show how you can invoke the debugger and choose the VM containing the design to which you want to attach.

In the VS Code image below, you can see four simulation sessions running, with our floating-point adder ROHD code in the main pane.  In the lower right-hand corner you can see the VM sessions and, importantly, the Dart Tooling Daemon (DTD) URI address you will use to connect.

{% include debugger-gallery.html columns="vertical" variant="startup" images="VSCode4.png|DTD.png" alts="VS Code debug session with ROHD Live Debugger available through DevTools|Dart Tooling Daemon connection view for choosing a debug session" captions="Start from a VS Code debug session.|Pick your session to debug by connecting to the Dart Tooling Daemon (DTD)." %}

### The ROHD Live Debugger Main Display

The main display combines five linked panes. On the left, the **Module Tree** controls the hierarchy level being inspected, while the **Shell** provides an advanced command interface. The three display panes present the selected module from complementary perspectives:

![The ROHD Live Debugger main display with its Module Tree, Shell, Details, Waveform, and Schematic panes]({{ site.baseurl }}/assets/images/rohd-live-debugger/ROHD_Debugger.png)

- **Details** shows the selected module's port signals, including their directions, widths, and current values.
- **Waveform** displays selected signals over simulation time. Note the support of structured signals in waveform tracking.
- **Schematic** displays the selected module's RTL connectivity.

Clicking on the connection icon![chain-link icon]({{ site.baseurl }}/assets/images/rohd-live-debugger/connect-vm.svg){: .debugger-inline-icon} will let you provide a new DTD URI address, at which point the **ROHD Live Debugger** discovers available VMs and lets you choose which one to attach. Attaching means querying the remote design for a basic dictionary to help with traversing the design.

## Explore One Module Across Linked Panes

The module tree is the control center: selecting a module in the elaborated hierarchy determines the level displayed in the Details, Waveform, and Schematic panes. That makes it possible to move from the structure of a design to its signals and behavior without losing your current place in the hierarchy.

{% include debugger-pane-layout.html variant="module-tree" tree_image="ModuleTree.png" tree_alt="Module hierarchy for the FilterBank design" tree_caption="Select the module to inspect." images="Details.png|Waveforms.png|Schematics.png" alts="Details pane listing signals for the selected FilterBank module|Waveform pane showing live simulation traces|Schematic pane showing selected FilterBank connectivity" captions="Details: signal directions, widths, and values.|Waveform: live traces for the selected hierarchy.|Schematic: connectivity alongside behavior." %}

## Follow a Live Simulation

Because the debugger stays attached while the simulation runs, it refreshes its view at each breakpoint, and in large designs this may take a few seconds. You can pause ![Pause tracking]({{ site.baseurl }}/assets/images/rohd-live-debugger/pause-tracking.svg){: .debugger-inline-icon} tracking and later click play ![Resume tracking]({{ site.baseurl }}/assets/images/rohd-live-debugger/play-tracking.svg){: .debugger-inline-icon} to catch up; in the meantime, simulation time continues to advance. Pausing freezes the current state, while resuming refreshes simulation data at the new breakpoint.

{% include debugger-gallery.html columns="two" images="paused.png|resume.png" alts="Debugger paused while the simulation is running|Debugger resuming and catching up to the running simulation" captions="Pause tracking while simulator runs.|Resume and catch up with the simulation." %}

## Inspect a Snapshot in Time

Position the waveform cursor to see the values at that time for the waveforms currently displayed. Then take a **snapshot** ![Take snapshot]({{ site.baseurl }}/assets/images/rohd-live-debugger/take-snapshot.svg){: .debugger-inline-icon} to capture every signal value in the design at that instant. Details and Schematic can show those captured values, including through an inline hover in the schematic pane.

{% include debugger-pane-layout.html variant="snapshot" tree_image="Snapshot.png" tree_alt="Taking a snapshot at the waveform cursor time" tree_caption="Take a snapshot at the selected waveform time." images="DetailedSnap.png|SchematicHover.png" alts="Details pane showing captured signal values at the snapshot time|Hovering over a schematic signal to see its captured value" captions="Inspect every design signal in Details at the snapshot.|See the captured value inline on schematic hover." %}

## Cross-Probe Across Panes

The Details, Waveform, and Schematic panes share signal selections through **Send** events. Send a signal selected in the schematic to add it to the waveform display, or send a waveform signal to zoom to and highlight it in the schematic. The same mechanism also makes a Details selection available to the other panes.

{% include debugger-gallery.html columns="two" images="SchematicSend.png|WaveformRcv.png" alts="Selecting a signal in the Schematic pane to send to the Waveform pane|Sent schematic signal received in the Waveform pane" captions="Select a signal in the Schematic pane.|Send it to add it to the Waveform pane." %}

## Cross-Probe to RTL in VS Code

Use the **Go to Design** menu to open the selected signal or block in its design source. Depending on the available source mapping, you can navigate directly to the ROHD ![ROHD source icon]({{ site.baseurl }}/assets/images/rohd-live-debugger/rohd-source-icon.png){: .debugger-inline-icon} or SystemVerilog® ![SystemVerilog source icon]({{ site.baseurl }}/assets/images/rohd-live-debugger/systemverilog-source-icon.png){: .debugger-inline-icon} representation in VS Code. We choose important locations, such as where a signal is named in ROHD, or where it is assigned in SystemVerilog®. There can be multiple locations to choose, such as the call stack in the ROHD generation code, or multiple assignments or the declaration in SystemVerilog®, for example. Other RTL formats are also available, such as SystemC®.

{% include debugger-gallery.html columns="two" images="SchematicGoToRohd.png|ROHDProbeRcv.png" alts="Selecting a signal in the Schematic pane to view its ROHD source|Selected signal opened in ROHD source in VS Code" captions="Select a signal to view in ROHD.|Open the selected signal in ROHD source in VS Code." %}

{% include debugger-gallery.html columns="two" images="SVProbe.png|SVProbeRcv.png" alts="Selecting a signal in the Schematic pane to view its SystemVerilog® output|Selected signal opened in SystemVerilog® output in VS Code" captions="Select a signal to view SystemVerilog® output.|Open the selected signal in SystemVerilog® output in VS Code." %}

## Cross-Probe From the Shell

The DTD-attached command-line shell offers the same cross-probe operation as the graphical panes. Use `send` to publish a selected signal to the linked Schematic and Waveform panes.

<!-- markdownlint-disable-next-line MD034 -->
![Sending a signal from the ROHD Debug Shell to the linked views]({{ site.baseurl }}/assets/images/rohd-live-debugger/ShellSend.png){: .debugger-shell-send}

Beyond cross-probing, the shell is a small, composable front end to the same hierarchy and connectivity API used by people and tools alike: select a signal, bind it with `let`, and pipe it through a graph query. The API's `find-cell`, `find-signal`, `fanin`, and `fanout` operations are also available programmatically, which is useful both for engineers exploring unfamiliar blocks and for AI coding agents tracing fanin and fanout.

`fanin` and `fanout` take one horizontal net hop by default; adding `transparent` follows an encountered input port into its non-leaf child block, repeating until it reaches ports on leaf blocks -- so a query can cross module boundaries without pretending arbitrary logic is a pass-through. Broader hierarchy and connectivity commands include `find-cell`, `find-signal`, `find-cells <regex>`, `find-signals <regex>`, `owner-cell`, and `parent-cell`.

The shell resolves signal paths in the process that owns the live occurrence handles and publishes only canonical paths to an available cross-probe participant (DevTools' local service when attached that way, or the VS Code extension's signal bus otherwise), so registered viewers receive the same signals regardless of which path led to the shell.

## What's Ahead

The **ROHD Live Debugger** is still evolving. Near-term work includes control of the VS Code debug controls from within our debugger, and potentially reverse cross-probing from VS Code back into our debugger. As with the schematic and wave viewers, the intended architecture is a generic command host where connectivity, waveform, and future providers register their own capabilities as well as separate applications. We expect these applications to be distributed as VS Code extensions as well, including local cross-probing support witin VS Code itself.

## Get Involved

The proposal and history for the debugger started with some early ideas in this discussion: <https://github.com/intel/rohd/discussions/418> and evolved from there!  So a suggestion or concept can evolve into a full blown capability. Everything here is open source, and we welcome contributors, adopters, and feedback. Come find us on the [ROHD Discord® server](https://discord.com/invite/jubxF84yGw) if you'd like to get involved.
