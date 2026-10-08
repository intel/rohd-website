---
title: "ROHD Wave Viewer: Try It in Your Browser"
permalink: /blog/rohd-wave-viewer-standalone/
last_modified_at: 2026-10-07
author: "Desmond A. Kirkpatrick"
---

Back in 2024 we [announced the ROHD Wave Viewer]({{ site.baseurl }}/blog/announcing-rohd-wave-viewer/) as an early, in-progress project. Since then it has grown into a fully capable waveform viewer, and today you can use it without installing anything at all: open a VCD, FST, or GHW file directly in your browser.

**[Open ROHD Wave Viewer](https://intel.github.io/rohd-wave-viewer/)**

<!-- markdownlint-disable MD033 -->
<video controls="controls" playsinline="playsinline" preload="metadata" poster="{{ site.baseurl }}/assets/images/rohd-wave-viewer-standalone/filter_bank_waves.png" style="display: block; width: 100%; height: auto;">
  <source src="{{ site.baseurl }}/assets/videos/rohd-wave-viewer-standalone/waveform-demo.mp4" type="video/mp4">
  Your browser does not support embedded video. You can <a href="{{ site.baseurl }}/assets/videos/rohd-wave-viewer-standalone/waveform-demo.mp4">download the wave viewer demo</a> instead.
</video>
<!-- markdownlint-enable MD033 -->

*Watch the viewer load a filter bank waveform and explore its signals.*

## A Real Waveform Viewer, No Install Required

The hosted web application is a full-featured, three-pane waveform viewer: module hierarchy and signal discovery on the left, the monitored-signal list in the middle, and waveforms on the right. Just open the app and pick a **VCD**, **FST**, or **GHW** file from your computer -- it's parsed and rendered entirely in the browser, and it never leaves your machine.

This is the same Flutter widget that powers the [ROHD DevTools extension]({{ site.baseurl }}/blog/announcing-rohd-devtool-extension/) and the VS Code extension, so what you learn here transfers directly to debugging a live simulation.

## What You Can Do With It

- **Find signals fast**: browse the module hierarchy, and filter by name, hierarchy path, or `*`/`?` wildcard patterns. Structured signals, ranges, named fields, and bit slices expand in place when hierarchy metadata is available.
- **Build a signal list your way**: select one or many signals -- including whole ranges -- and add them with a double-click or the context menu. The list supports duplicate rows, multi-row drag reorder, groups, and undo/redo.
- **Choose the right format per signal**: binary, hex, octal, unsigned or signed decimal, ASCII, or the waveform default, applied consistently across the signal list, value display, and waveform panes.
- **Navigate like you mean it**: drop a primary marker, pan and zoom at the cursor, draw a region to zoom into, or fit the whole trace to the viewport. Select multiple focused signals and jump to the next or previous rising edge, falling edge, or matching value across the selection. An optional measurement marker reports delta time and derived frequency relative to the primary marker.
- **Save your work**: reload waveform files without losing viewer state, save or restore a monitored-signal list -- or the entire viewer session, including formats, filters, markers, layout, and viewport -- as versioned JSON, and export any pane as a PNG.
- **Cross-probe when embedded**: inside the VS Code extension, selected signals can cross-probe with registered waveform and schematic viewers through the companion ROHD extension. The selected signal can also navigate to its available ROHD, generated SystemVerilog, or SystemC source location.

## Same Widget, Every Context

ROHD Wave Viewer was designed from the start to be modular: the parsers for waveform file formats are independent utilities, and the viewer GUI itself is a stand-alone Flutter widget. That design is why today it shows up as:

- The **hosted web application** described in this post.
- A **native desktop binary** you can point at a file on the command line.
- A **VS Code extension**, cross-probing with the schematic viewer and the rest of the ROHD DevTools stack.
- Directly **embedded inside the ROHD DevTools extension**, viewing waves live as a simulation runs under the debugger.

## From Trace to Live Debugger

The browser app is useful for a completed trace, but the same viewer can become part of an active ROHD debugging session. In a compatible DevTools host, it can receive hierarchy and waveform data directly during simulation, update waveforms incrementally, and show a design snapshot at the current marker time. Live-tracking mode keeps the view following execution when that is useful, while the familiar marker, filters, formats, and edge navigation still let you stop and investigate a particular cycle.

## Try It Today

There's nothing to set up -- open the [ROHD Wave Viewer](<https://intel.github.io/rohd-wave-viewer/?waveFormFile=assets%2Fwaveforms%2Ffilter_bank.fst&signalList=FilterBank%2Fclk&signalList=FilterBank%2Freset&signalList=FilterBank%2Fsample1&signalList=FilterBank%2Fch0%2FdataOut&signalList=FilterBank%2Fstate&signalList=FilterBank%2FvalidIn&signalList=FilterBank%2FsampleIn&signalList=FilterBank%2FdataOut&signalList=FilterBank%2FchannelOut&signalList=FilterBank%2Fcontroller%2FloadingPhase&signalList=FilterBank%2Fcontroller%2FdoneFlag>)

and load a waveform file. If you want the native binary, the VS Code extension, or you're interested in contributing a new file-format parser, the project's [README](https://github.com/intel/rohd-wave-viewer) has the developer quick start.

As always, the [ROHD Discord server](https://discord.com/invite/jubxF84yGw) is the best place to ask questions or tell us what to build next. To report a problem, please [file an issue on GitHub](https://github.com/intel/rohd-wave-viewer/issues).
