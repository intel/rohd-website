---
title: "The ROHD Live Debugger: A DevTools Extension for Schematics, Waves, and a Query Shell"
permalink: /blog/rohd-live-debugger-devtools-extension/
last_modified_at: 2026-09-30
author: "Desmond A. Kirkpatrick"
---

In early 2024 we [introduced the ROHD DevTools extension]({{ site.baseurl }}/blog/announcing-rohd-devtool-extension/) as a Flutter-based debugger that could show the ROHD module hierarchy and live signal values while a design was paused in a breakpoint. Since then, it has grown into the **ROHD Live Debugger**: it attaches to a running ROHD simulation, displays signal values at a selected simulation time directly on a rendered schematic of the RTL, and shows the corresponding waveforms in a linked waveform display. Below is a walkthrough of what a typical debug session looks like today, using a small filter bank design as the example.

## Connect to a Running Simulation

The ROHD Live Debugger attaches to the Dart VM running your ROHD simulation over the Dart Tooling Daemon (DTD), either automatically when opened from Flutter DevTools during a VS Code debug session, or standalone by discovering running VMs through a DTD URI or pasting a VM service URI directly.

<!-- markdownlint-disable-next-line MD034 -->
![Connecting to a running ROHD simulation]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/connect-vm.png)

## Three Linked Panes: Details, Waveform, and Schematic

Once connected, the module tree on the left shows the elaborated design hierarchy, and the right-hand side offers three linked panes for exploring it.

The **Details** pane lists every signal on the selected module, with its bit width, direction, and live value:

<!-- markdownlint-disable-next-line MD034 -->
![The Details pane listing signals for the FilterBank module]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/details-initial.png)

The **Waveform** pane is the same [ROHD Wave Viewer]({{ site.baseurl }}/blog/rohd-wave-viewer-standalone/) widget we covered in a recent post, now fed directly by the live simulation instead of a static file:

<!-- markdownlint-disable-next-line MD034 -->
![The Waveform pane showing live simulation traces]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/waves-initial.png)

And the **Schematic** pane is the [ROHD Schematic Viewer]({{ site.baseurl }}/blog/announcing-rohd-schematic-viewer/), rendering the connectivity of the elaborated design so you can see structure alongside behavior:

<!-- markdownlint-disable-next-line MD034 -->
![The Schematic pane showing the elaborated FilterBank connectivity]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/schematic-initial.png)

## Pause and Resume, In Step With the Simulation

Because the debugger stays attached while the simulation runs, it tracks execution as it happens. Pausing the debugger -- for example, at a breakpoint -- freezes the view so you can inspect the design at that instant:

<!-- markdownlint-disable-next-line MD034 -->
![The debugger paused while the simulation is stopped at a breakpoint]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/paused.png)

Resuming lets the debugger catch back up to the running simulation, with the waveform display extending to show everything that happened while it was paused:

<!-- markdownlint-disable-next-line MD034 -->
![The debugger resuming and catching up to the running simulation]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/resume.png)

## Selecting a Snapshot in Time

The waveform's cursor is more than a marker: dropping it at a point in time takes a **snapshot** of the entire design at that instant.

<!-- markdownlint-disable-next-line MD034 -->
![Selecting a snapshot time on the waveform]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/snapshot.png)

The Details pane then shows every signal's value as of that selected snapshot time, not just the value at the current end of simulation:

<!-- markdownlint-disable-next-line MD034 -->
![The Details pane showing signal values at the snapshot time]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/snapshot-details.png)

Hovering over any signal gives the same information inline, right where you're looking, without needing to leave the schematic or waveform view:

<!-- markdownlint-disable-next-line MD034 -->
![Hovering over a signal to see its value at the selected time]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/hover.png)

## A Query Shell for Hierarchy and Connectivity

Alongside the graphical viewers, the extension ships a DTD-attached command-line shell (`bin/rohd_shell.dart`) for people who'd rather query a design than click through it. It supports a small, composable query language: select a signal, bind it with `let`, and pipe it through a graph query.

<!-- markdownlint-disable-next-line MD034 -->
![The ROHD Debug Shell resolving find-signal and get-value queries against the live design]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/shell.png)

```text
let s1 = find-signal FilterBank/controller/currentState
let fe = find-signal FilterBank/controller/filterEnable
get-value $fe
```

`fanin` and `fanout` take one horizontal net hop by default; adding `transparent` follows an encountered input port into its non-leaf child block, repeating until it reaches ports on leaf blocks -- so a query can cross module boundaries without pretending arbitrary logic is a pass-through. Broader hierarchy and connectivity commands are available too, including `find-cell`, `find-signal`, `find-cells <regex>`, `find-signals <regex>`, `owner-cell`, and `parent-cell`, all operating on live target objects so an alias keeps its identity instead of being re-serialized on every query.

### Occurrence Handles Instead of Hierarchical Strings

Under the hood, signals and cells are passed between components -- and to and from the shell -- as **occurrence handles**: compact, portable address representations rather than cumbersome hierarchical path strings. A handle like `$s1` or `$fe` carries a signal's canonical path, leaf name, width, and stable address as a single lightweight reference, so a query result can be piped into the next command, sent across the DTD boundary to a cross-probe participant, or handed to an AI agent without re-parsing or re-resolving a string path each time. This is also why aliases retain their identity across a shell session: `let fe = find-signal FilterBank/controller/filterEnable` binds a handle, not a string, so a later command like `send $fe` operates on the same live object the shell already resolved.

### Cross-Probing From the Shell

The shell can also act as a cross-probe agent: `send` resolves signal paths in the process that owns the live occurrence handles and publishes only canonical paths to an available cross-probe participant (DevTools' local service when attached that way, or the VS Code extension's signal bus otherwise), so registered viewers receive the same signals regardless of which path led to the shell.

```text
rohd> send $fe
ok: sent 1 signal
```

Sending a signal from the shell highlights it directly on the schematic:

<!-- markdownlint-disable-next-line MD034 -->
![A signal sent from the shell highlighted on the schematic]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/send-schematic.png)

and adds it to the linked waveform display, right alongside the signals you were already monitoring:

<!-- markdownlint-disable-next-line MD034 -->
![The same signal appearing in the linked waveform display]({{ site.baseurl }}/assets/images/rohd-live-debugger-devtools-extension/send-waveform.png)

### An API for Humans and AI Alike

The shell's commands are a thin, convenient front end over a real backing API for hierarchy and connectivity traversal -- the same `find-cell`, `find-signal`, `fanin`, and `fanout` operations are just as usable programmatically as they are interactively. That matters because ROHD elaboration is fast: a large design can be elaborated and ready to query in seconds, not minutes. The combination of quick elaboration and a queryable connectivity API makes this a genuinely useful capability for comprehending and analyzing large designs, whether the one doing the exploring is a human engineer trying to understand an unfamiliar block or an AI coding agent tracing fanin/fanout to answer a question about a design it has never seen before.

## What's Ahead

The DevTools extension is still evolving. Near-term work includes clearing shell aliases when the underlying netlist changes, broader connectivity fixtures for buses, inouts, constants, and multiple drivers, and optional query limits/pagination to keep large-design responses bounded. As with the schematic and wave viewers, the intended architecture is a generic command host where connectivity, waveform, and future providers register their own capabilities rather than shipping as separate tool-specific executables.

## Get Involved

The full proposal and history for the extension started in this discussion: <https://github.com/intel/rohd/discussions/418>. Everything here is open source, and we welcome contributors, adopters, and feedback. Come find us on the [ROHD Discord server](https://discord.com/invite/jubxF84yGw) if you'd like to get involved.
