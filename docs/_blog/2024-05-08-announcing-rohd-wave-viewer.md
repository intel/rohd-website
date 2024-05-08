---
title: "Announcing ROHD Wave Viewer"
permalink: /blog/announcing-rohd-wave-viewer/
last_modified_at: 2024-05-08
author: "Max Korbel"
---

The ROHD Wave Viewer is now open-source and available at <https://github.com/intel/rohd-wave-viewer>!  The project is still a work in progress, but development will happen in the open, and contributors are more than welcome.

## Motivation

The ROHD Wave Viewer was initiated for a handful of reasons:

- Most of the best wave viewers were expensive and proprietary.  The available open source and/or free wave viewers were okay, but not great. [GTKWave](https://gtkwave.sourceforge.net/) is one of the most popular free waveform viewers.  [Surfer](https://surfer-project.org/) started gaining popularity around the same time as ROHD Wave Viewer was being developed and seems to have some overlap on motivations and goals and also appears to be heading in a great direction.
- The ROHD ecosystem needs some improved debug capabilities.  The [ROHD Devtools Extension](https://intel.github.io/rohd-website/blog/announcing-rohd-devtool-extension/) is a great step in that direction, and including a waveform viewer within it would really boost its capabilities.
- There are not a lot of great options (especially free and open-source) for inserting a waveform into some other app or website, or for parsing and analyzing waveform files.

## Features and Goals

The ROHD Wave Viewer is going to be **modular** so that different pieces can be easily reused in different contexts.  For example, the parsers for different waveform file formats (e.g. VCD) will be independently usable utilities from the GUI, and the wave viewer GUI will be a stand-alone Flutter widget so that anyone can drop in a wave viewer to their app or website.

ROHD Wave Viewer will also be released in multiple contexts:

- A package (or packages) on [pub.dev](https://pub.dev) for the Flutter widgets and parsing utilities.
- A stand-alone binary utility that can be run natively on your computer, parsing various waveform file formats.
- Integrated into the ROHD Devtools Extension, enabling viewing of waves as the simulation is executing/being debugged.
- A Flutter web-app version, with no installation or download required.

## Current State and Looking Ahead

As of this writing, the front-end GUI for ROHD Wave Viewer has a great well-architected start upon which to build.  The parsers are not yet implemented, so it's not yet ready for hardware debug usage.

This is open-sourced *early* so that it can be developed in the open in collaboration with the community!  There are a lot of things that need implementing, so if this sounds interesting to you, it's a great time to get involved.  The [ROHD Discord server](https://discord.com/invite/jubxF84yGw) is a friendly place to ask questions and start out.
