---
title: "Announcing ROHD"
permalink: /blog/announcing-rohd/
last_modified_at: 2023-07-28
author: "Max Korbel"
---

Leave your SystemVerilog woes behind! I've been working on the Rapid Open Hardware Development (ROHD) framework at Intel, and it's finally open source!

Check out the GitHub repo here: <https://github.com/intel/rohd>

ROHD (pronounced like "road") is a framework for describing and verifying hardware in the Dart programming language. ROHD enables you to build and traverse a graph of connectivity between module objects using unrestricted software.

This project aims to bring hardware development into the modern era, taking advantage of recent innovations in the software industry. You can model your hardware with ROHD, simulate natively with the fast ROHD simulator, verify using a testbench written in a modern programming language (Dart), and much more! When you're ready to pass it down to synthesis or an FPGA, your hardware model can be converted to structurally similar SystemVerilog with port and signal names maintained.

There's a lot of really big, exciting things still under development. The repository is open for contribution by anyone! I'm also hoping to build a community around open source hardware design and verification and an ecosystem of packages that build upon ROHD.

If you're used to using SystemVerilog or VHDL, or even another more modern hardware development language such as Chisel or PyMTL, I think you'd really like ROHD. It lets you avoid writing perl generator scripts and stop worrying about build systems and EDA tools. ROHD makes hardware development as fun as it should be.

ROHD has a major focus on solving real problems faced by hardware engineers today. It aims to be ready for execution rather than an academic proof of concept. While ROHD makes design much easier, verification gets first class consideration as well.

You can submit issues for new feature ideas (<https://github.com/intel/rohd/issues/new/choose>) or join the conversation on the discussions page (<https://github.com/intel/rohd/discussions>).

Feel free to reach out, I'd love to hear your thoughts!

--------------

This post was originally shared on LinkedIn [here](https://www.linkedin.com/posts/maxkorbel_github-intelrohd-the-rapid-open-hardware-activity-6849189983014809600-lB5B?utm_source=share&utm_medium=member_desktop).
