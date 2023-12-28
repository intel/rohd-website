---
title: "Announcing the ROHD Hardware Component Library (ROHD-HCL)"
permalink: /blog/announcing-rohd-hcl/
last_modified_at: 2023-12-28
author: "Max Korbel"
---

Stop reinventing the wheel (or FIFO) with hardware development!  The ROHD Hardware Component Library (ROHD-HCL) finally has its first release at v0.1.0!  ROHD-HCL is a hardware component library developed using ROHD, aiming to collect a set of reusable, configurable hardware and verification components that can be easily reused.

Check it out on GitHub here: <https://github.com/intel/rohd-hcl>

The software world leverages open source packages, versioning, and dependency management so that complex tasks can be achieved through stitching together existing libraries. Look at Python and <https://pypi.org/>, with an extensive set of packages for everything to help you get started in any direction. However, the hardware world is stuck in the past!  There's two main parts to the problem: the language and the ecosystem.

SystemVerilog is not the most portable language: different tools support different subsets of the language, designs come with settings requirements (elab/analysis options, defines, etc.), project-specific macros, name uniquification may be required, and all transitive dependencies must be handled by the end user.  Reusing a simple component, even one you wrote in the past yourself, can sometimes prove to be harder than just rewriting it again.

There's not enough open-source hardware out there, and what's there can be hard to trust. Will it build in my environment? Has it been sufficiently tested? Does it synthesize correctly (and have good performance)? The story for open-source verification components is even worse due to major limitations in open-source or free tools for supporting industry standard methodologies like UVM.

Enter ROHD-HCL: a hardware component library implemented in ROHD!  All components in ROHD-HCL are highly configurable, heavily verified, well documented, easy to integrate, and convertible (like all ROHD modules) into clean SystemVerilog.  Right now, you can find small components like encoders/decoders, arbiters, queues, find/count, rotators, etc. as well as BFMs, checkers, trackers, loggers, and even standard interface implementations.  Over time, the set of components will grow from community contributions in breadth, depth, and complexity.  The components added focus first on breadth and correctness, followed by depth and performance.

Take a look at the [generator web app](https://intel.github.io/rohd-hcl/confapp/) as well, which lets you explore some of the available components, configure them, and generate SystemVerilog!

ROHD-HCL is not intended to be the only place for ROHD hardware components.  Anyone can build their own packages, libraries, components, automation, etc. and publish them on <https://pub.dev/>, thus growing the ecosystem!  The pub package manager will handle all your version solving, transitive dependencies, etc. across any of your hardware package dependencies, just like you expect in the software world!

If you've been following ROHD closely, you probably have noticed the [repository for ROHD-HCL](https://github.com/intel/rohd-hcl) has already been open source for a while now.  This is the first formal release of the library at <https://pub.dev/packages/rohd_hcl>.  Thank you to everyone who has contributed thus far to build this out into its current state!

As always, see the ROHD website for more information, tutorials, user guides, etc.: <https://intel.github.io/rohd-website/>
