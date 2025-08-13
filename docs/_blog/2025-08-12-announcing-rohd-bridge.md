---
title: "Announcing ROHD Bridge"
permalink: /blog/announcing-rohd-bridge/
last_modified_at: 2025-08-12
author: "Max Korbel"
---

Designing large hardware systems can be tough -— especially when it comes to managing hierarchy and connecting all the pieces. Even if the top level of your SoC is mostly just wiring, keeping everything organized and refactorable can be a real challenge.

Most existing tools for this job are slow, rigid, or force you into limiting languages and formats. They can be confusing, brittle, and not much fun to use.

That’s why we built ROHD Bridge: a new open-source library for automating hardware connectivity and hierarchy, built on top of ROHD and Dart. ROHD Bridge is:

- **Extremely fast** – Even huge designs assemble in seconds, or at worst, a few minutes.
- **Flexible** – Use the Dart API to build, connect, and refactor your hierarchy however you want.
- **Powerful** – Automate connections, pull up ports/interfaces, and generate SystemVerilog for your whole design.
- **Modern** – No more outdated tech or brittle formats. Just open-source, portable, and easy to extend APIs.

Write programs in a modern software language to automate your connectivity and hierarchy.  Decouple connectivity and use-case-specific hierarchy requirements, from testbenches to physical partitioning.  Build configurable IPs, generate statically resolved designs, and deliver generator applications that can read customer specifications.

If you’re tired of legacy tools or just want a better way to assemble and connect your hardware, give ROHD Bridge a try! The [README](https://github.com/intel/rohd-bridge) has details, examples, and a full API guide. We’re excited to see what you build!
