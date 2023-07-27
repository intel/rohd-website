---
layout: splash
permalink: /
header:
  overlay_color: "#5e616c"
  overlay_image: assets/images/adobestock-183503230.jpeg
  actions:
    - label: "<i class='fas fa-download'></i> Install now"
      url: "/get-started/setup/"
    - label: "<i class='fas fa-cloud'></i> Try it in-browser"
      url: "https://dartpad.dev/?id=375e800a9d0bd402c9bfa5ebe2210c40"
excerpt: >
  The Rapid Open Hardware Development (ROHD) framework is a framework for describing and verifying hardware in the Dart programming language. <br />
  <small><a href="https://github.com/intel/rohd/releases">Latest release</a></small>
feature_row:
  - image_path: assets/images/adobestock-312879613.jpeg
    alt: "Modern & Productive"
    title: "Modern & Productive"
    excerpt: "<p>Write fewer lines of code for your design and verification in a modern IDE. ROHD is completely open source, so debug all the way through from your testbench, through design generation, and even into the simulator itself.</p><p>ROHD uses the <a href='https://dart.dev/'>Dart programming language</a>, which comes with a simple and fast build system and the great <a href='https://pub.dev'>pub</a> package manager.</p>"
    
  - image_path: assets/images/adobestock-321373976.jpeg
    alt: "Quality Focused"
    title: "Quality Focused"
    excerpt: "<p>The ROHD simulator is a built-in, fast, event-based, 4-value hardware simulator with waveform dumping.</p><p>Use <a href='https://github.com/intel/rohd-vf'>ROHD-VF</a> to build scalable testbenches and <a href='https://github.com/intel/rohd-vf'>ROHD Cosim</a> to interact with SystemVerilog simulators.</p><p>Unit test your hardware with a great testing framework and minimal overhead.</p>"

  - image_path: assets/images/adobestock-196076777.jpeg
    alt: "Flexible & Extensible"
    title: "Flexible & Extensible"
    excerpt: "<p>Achieve the dream of hardware abstraction via composition of building blocks with ROHD. ROHD comes with built-in abstractions for procedural behavior, finite state machines, pipelining, and more.</p><p>Use interfaces and unrestricted software to accelerate integration tasks. Dynamically create and connect module ports.</p><p>Kick-start development and use <a href='https://github.com/intel/rohd-vf'>ROHD-HCL</a> for pre-validated components for your design and testbench.</p>"
      
feature_row2:
  - image_path: assets/images/rohdvfdiagram1.png
    alt: "ROHD Verification Framework (ROHD-VF)"
    title: "ROHD Verification Framework (ROHD-VF)"
    excerpt: "<p>A verification framework built upon the Rapid Open Hardware Development (ROHD) framework. It enables testbench organization in a way similar to UVM.</p><p>A key motivation behind it is that hardware testbenches are really just software, and verification engineers should be empowered to write them as great software. The ROHD Verification Framework enables development of a testbench in a modern programming language, taking advantage of recent innovations in the software industry.</p><p><a href='https://github.com/intel/rohd-vf'><i class='fab fa-fw fa-github'></i>Github</a></p>"

feature_row3:
  - image_path: assets/images/gettyimages-847623056.jpg
    alt: "ROHD Hardware Component Library (ROHD-HCL)"
    title: "ROHD Hardware Component Library (ROHD-HCL)"
    excerpt: "<p>A hardware component library developed with ROHD. This library aims to collect a set of reusable, configurable components that can be leveraged in other designs. These components are also intended as good examples of ROHD hardware implementations.</p><p>Components are focused on correctness, are heavily validated, and come with excellent documentation. Verification components are provided as well, including checkers for proper usage and trackers to log interesting activity.</p><p><a href='https://github.com/intel/rohd-hcl'><i class='fab fa-fw fa-github'></i>Github</a></p>"

feature_row4:
  - image_path: assets/images/adobestock-573439215.jpeg
    alt: "ROHD Cosim"
    title: "ROHD Cosim"
    excerpt: "<p>A Dart package built upon ROHD for cosimulation between the ROHD Simulator and a SystemVerilog simulator.</p><p>Mix and match modules and verification components across ROHD and SystemVerilog for your design and testbench and cosimulate it all together. ROHD Cosim comes with different configurations depending on whether you have custom build and/or simulation flows.</p><p><a href='https://github.com/intel/rohd-cosim'><i class='fab fa-fw fa-github'></i>Github</a></p>"
---

<!-- Unsplash Image Source: https://unsplash.com/photos/FVgECvTjlBQ, https://unsplash.com/photos/KuCGlBXjH_o -->

{% include feature_row %}

{% include feature_row id="feature_row2" type="left" %}

{% include feature_row id="feature_row3" type="right" %}

{% include feature_row id="feature_row4" type="left" %}
