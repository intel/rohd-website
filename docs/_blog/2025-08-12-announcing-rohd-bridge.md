---
title: "Announcing ROHD Bridge"
permalink: /blog/announcing-rohd-bridge/
last_modified_at: 2025-08-12
author: "Max Korbel"
---

When building large, complex hardware designs, it can be surprisingly difficult to manage instantiaion, hierarchy, and connections between many interdependent subsystems and IPs.  Even though the top-level of a large SoC doesn't usually have a substantial amount of meaningful digital logic, just routing signals from point A to point B can be challenging to get right, especially in a way that is easily refactorable.

Various tools exist, whether from vendors or built as proprietary flows within companies, to address this collection of problems.  However, they often suffer from long run times, depend on outdated technologies, and/or invent new languages and specification formats.  These tools and inputs can be brittle or limiting, and error messages can be confusing.

Introducing ROHD Bridge: a new library built upon ROHD for building hierarchy and making connections for large hardware designs!  ROHD Bridge has a flexible API built in Dart, fully compatible with ROHD, and is lightning fast, even for the largest and most complex designs.

ROHD Bridge is now open-source and available at <https://github.com/intel/rohd-bridge>!  Check out the README to learn more and get started!

