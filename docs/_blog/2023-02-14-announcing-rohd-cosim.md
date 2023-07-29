---
title: "Announcing ROHD Cosim"
permalink: /blog/announcing-rohd-cosim/
last_modified_at: 2023-07-28
author: "Max Korbel"
---

I'm excited to announce the third official package release in the ROHD ecosystem after ROHD and ROHD-VF: ROHD Cosim (<https://github.com/intel/rohd-cosim>)! ROHD Cosim provides the ability to cosimulate between the ROHD simulator and a variety of SystemVerilog simulators.

As a reminder, ROHD (<https://github.com/intel/rohd>) aims to bring hardware development into the modern era, taking advantage of recent innovations in the software industry. You can model your hardware with ROHD, simulate natively with the fast ROHD simulator, verify using a testbench written in a modern programming language (Dart), and much more! When you're ready to pass it down to synthesis or an FPGA, your hardware model can be converted to structurally similar SystemVerilog with port and signal names maintained. ROHD aims to replace SystemVerilog for both design and verification.

Recall that ROHD-VF (<https://github.com/intel/rohd-vf>) is a verification framework built upon ROHD which enables building scalable testbenches that are similar in structure to UVM testbenches, but without the boilerplate, macros, opinionated patterns, and limitations of SystemVerilog.

And now, ROHD Cosim unlocks a ton of power through interaction with legacy SystemVerilog in cosimulation.

Here are some exciting new use cases:

- Instantiate and cosimulate a SystemVerilog module within a larger ROHD module
- Instantiate a ROHD module and cosimulate it within a larger SystemVerilog module
- Connect multiple SystemVerilog and ROHD modules together using ROHD and cosimulate all together
- Build a ROHD-VF testbench around a SystemVerilog design and cosimulate
- Build a ROHD design and test it with your SystemVerilog UVM testbench
- Build a mixed SystemVerilog UVM and ROHD-VF testbench around a mixed SystemVerilog and ROHD design
- Any other mixing and matching you can imagine!

This truly makes ROHD-VF as an execution-ready alternative to UVM for both new and legacy designs. We've been using it at Intel already for a while for some real products and done some really cool stuff with it (though unfortunately I'm limited in what I can share here).

The instantiated SystemVerilog modules in ROHD look and behave just like any other ROHD module. You can even still run your ROHD simulation in the Dart debugger and step through, and the SystemVerilog simulator will step along with you and wait while you inspect at breakpoints!

ROHD Cosim, like ROHD and ROHD-VF, has been published on pub.dev and is ready to use: <https://pub.dev/packages/rohd_cosim>

You can join the discussion on ROHD Cosim here: <https://github.com/intel/rohd-cosim/discussions>. Check out the repositories for full documentation and for more ways to engage in the community.

---------------

This post was originally shared on LinkedIn [here](https://www.linkedin.com/posts/maxkorbel_github-intelrohd-cosim-cosimulation-for-activity-7031422527306412033-JyIJ?utm_source=share&utm_medium=member_desktop).
