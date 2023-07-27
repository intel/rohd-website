---
title: "ROHD Forum Agenda & Minutes"
permalink: /forum/rohd-forum-minutes/
excerpt: "ROHD Forum Agenda & Minutes"
last_modified_at: 2023-07-27
toc: true
---

### Future agenda topics

- SSA in Combinational
- Arrays and Structures
- Pair interfaces
- Discussion on HLS integration with ROHD
- Growing contribution
- Producing video tutorials

### July 5, 2023 @ 8AM Pacific Time

- Opens

### June 7, 2023 @ 8AM Pacific Time

- Opens

### May 3, 2023 @ 8AM Pacific Time

- Opens

### April 5, 2023 @ 8AM Pacific Time

- Opens
  - New logo
- [The ROHD Hardware Component Library (ROHD-HCL)](https://github.com/intel/rohd-hcl)
- The new [ROHD website](https://github.com/intel/rohd-website) repository
  - Migration of ROHD Forum minutes to website
  - Organization using git subtrees for repo-specific documentation

### March 8, 2023 @ 8AM Pacific Time

- GitHub Codespace setup for ROHD
  - Available on ROHD, ROHD-VF, and ROHD Cosim
- [ROHD Cosim](https://github.com/intel/rohd-cosim) - a package for cosimulation between the ROHD simulator and SystemVerilog simulators.
- Update on CIRCT integration with ROHD
  - Open source soon!
- ROHD tutorials
  - Available now in `doc/tutorials` on the ROHD repo, ~1 chapter per week written
- The new ROHD website
  - New landing page coming with a new repo soon!

### February 8, 2023 @ 8AM Pacific Time

- Low attendance due to conflicts

### January 11, 2023 @ 8AM Pacific Time

- Discussed some long-term strategy of the ROHD ecosystem

### December 7, 2022 @ 8AM Pacific Time

- Discussed some implementation updates and strategies on some attendees' ROHD projects

### November 9, 2022 @ 8AM Pacific Time

- Clock dividers
  - Discussed this issue: <https://github.com/intel/rohd/issues/191>
  - Potential solution: use topological sort to determine order that `Sequential`s execute.
- Stack overflow
  - Discussed this issue: <https://github.com/intel/rohd/issues/194>
  - Discussed multiple ways to either mitigate or entirely resolve.
  - First good step is reducing the stack requirements for signal propagation, which doesn't fix the issue entirely but makes it harder to fix and also improves simulation performance.
  - Full solution would need to avoid recursive calls, at least after some threshold.

### October 5, 2022 @ 8AM Pacific Time

- Structs and multi-dimensional arrays
  - Arrays helpful for integration and backend work
  - People dont usually use structs at interfaces in the industry
  - Arrays are pretty simple to implement in ROHD, but structs are a little more complex because they need to be generated in output as well.
  - Probably worth implementing at least arrays.
- Parameterized interfaces
  - Parameterizing just the interface, and just for signal width, with no expressions, is not too hard.
  - Passing parameters through logic, or doing parameter expressions, or safely checking for parameter expression equality, or conditional/controlled generation of logic using parameters can be very tricky to implement and convert to SystemVerilog.
    - Also, can add limitations on usage of parameters based on SystemVerilog limitations, which philosophically goes a bit against other things ROHD enables.
  - Parameters are most useful to people delivery top-level SystemVerilog to others, rather than for original design or internal usage.
  - Maybe not worth implementing parameters in the short term.

### August 31, 2022 @ 8AM Pacific Time

- New performance bug fix
  - Discussed this PR: <https://github.com/intel/rohd/pull/156>
- Benchmarking
  - 2 parts
    - Microbenchmarking
      - Isolate one small feature of the language, identify how long that takes
      - Enumerate that each individual functionality works quickly, make unit tests, etc.
      - Usually helps more for regressions
    - Medium-sized programs
      - Do something non-trivial
      - There's an attempt to benchmark programs against each other, runs ~40 programs in different languages and compares against each other - has shown to be helpful for identifying tradeoffs and benefits of optimizations
        - Maybe this? <https://benchmarksgame-team.pages.debian.net/benchmarksgame/index.html>
      - It may be hard to find/create these
  - Benchmarking usually has some noise and performance fixes have some tradeoffs
  - Should measure mixed simple programs rather than microbenchmarks for improving performance

### July 27, 2022 @ 8AM Pacific Time

- Discord server for ROHD
  - Created for the entire public ROHD community
  - <https://discord.com/channels/1001179329411166267/1001179329411166270>
- SystemVerilog ROHD wrapper generator
  - Starting out as an experiment to wrap entire SV component libraries, but eventually aim to make a generic tool for generating `ExternalSystemVerilog` ROHD wrappers for SV modules.
- Discussion on v0.3.0 updates
  - Walked through changelog for 0.3.0: <https://github.com/intel/rohd/blob/main/CHANGELOG.md>
- Update on FSM abstraction
  - Did some live modifications to the traffic light example, experimenting with ways to make it better.
- Discussion on encoding, enums, named constants, and generated SV
  - Add a one-hot and gray code encoding utility
  - How to export enumerations as constant names instead of constants (use localparam instead of enum)
  - Filed an issue based on discussion: <https://github.com/intel/rohd/issues/139>

### June 22, 2022 @ 8AM Pacific Time

- ROHD Tutorials
  - There's interest in providing more tutorials for ROHD, including video tutorials
  - Probably just a webcam for initial tutorials
- Comment generation
  - There's interest in better control of comment generation in the output SystemVerilog

### May 25, 2022 @ 8AM Pacific Time

- Opens
  - ROHD feature suggestions
    - Easier way to add a special SystemVerilog macro? Controllable and flexible for uniquification.
    - A mechanism to inject a header into generated files.
      - Some tools at companies require certain headers to be added to source code files.
      - A way to add/encourage documentation addition in the generated header.
  - Review of ROHD architecture, functionality, and usage best practices

### April 13, 2022 @ 8AM Pacific Time

- `LogicValue` behavior update
  - `LogicValues` and `LogicValue` have been merged into one `LogicValue`
- Open Issues & Features
  - 39 issues currently open, spanning bugs and enhancements
    - <https://github.com/intel/rohd/issues>
  - All TODO's converted to issues
  - Major features not listed
- Publicity and marketing for ROHD
  - Conferences
    - ICCAD
  - Universities
    - Find people with University contacts
    - Universities we are partnered with
  - SEO to show up in Google search results
  - Answers on question websites (StackOverflow, Quora)
  - AMA Session on Reddit (some area covering simulators, HDLs, etc.)
- Update on FSM abstraction

### March 16, 2022 @ 8AM Pacific Time

- Discussions on on CIRCT and ROHD
- Discussions on debug hints in generated code
- Discussions on external open source adoption of ROHD

### February 16, 2022 @ 8AM Pacific Time

- Updates, Opens, and Questions
  - Working on constraint solver performance analysis, suspect z3 is the bottleneck currently
- Containers with ROHD
  - We've set up a couple types of singularity containers which enable running ROHD with a variety of open source and vendor tools in different systems.
- Cosimulation update
  - New re-implementation of cosimulation functionality is being prepared for open source, using more robust mechanisms for interactions with various SystemVerilog simulators.
- Examples and tutorials
  - Topics:
    - What types of examples and tutorials would be most valuable for those getting started with ROHD?
    - Review examples from other options like Chisel and cocotb.
  - Recently a new FIR filter was contributed to the ROHD repository based on an example they saw on Chisel.
  - Examples should showcase how having simulation and generation both in the same runtime is beneficial.
    - Show that you can dynamically evaluate code without leaving the dart environment (e.g. run a simulation and view the output of the counter).
    - Useful to have software interact with a real hardware model without the need for hooking up to a separate RTL simulation process.
  - Interactive debug and waveform viewing
    - A waveform viewer plugin for Visual Studio Code (not free for >8 signals): <https://marketplace.visualstudio.com/items?itemName=wavetrace.wavetrace>
    - Another waveform viewer that is not integrated, but likely to be integrable: <https://github.com/raczben/fliplot>
    - GTKWave, a free waveform viewer.  Can open VCD's generated by ROHD. <http://gtkwave.sourceforge.net/>
    - Some examples rendering waveforms in Jupyter:
      - <https://github.com/devbisme/myhdlpeek/blob/master/examples/complete.ipynb>
      - <https://nbviewer.org/github/pcornier/1pCPU/blob/master/pCPU.ipynb>
    - Waveform diagram generator from text input: <https://wavedrom.com/>
    - Some discussion on how to achieve interaction between waveform viewing and live debug of a hardware model generated by ROHD.
    - A special kind of waveform that handles complex protocols, perhaps shows state during the simulation, could be interesting.  Adding arbitrary strings to a waveform viewer could open some possibilities.
  - Generate hardware or testbench collateral from external sources (e.g. file parsing).  It is difficult to generate a checker, stimulus, or hardware from an input file in just SystemVerilog, but very easy in ROHD.
    - A demonstration of a file format that can be used for simple vectors, even across cycles (similar to `Vector` in the ROHD unit tests).
    - Some generic glue logic that can take flexible inputs to generate things would be a good example.
  - Utilizing Dart's "hot reload" feature
    - Modify dart testbench code live during a simulation to modify checking, stimulus, etc.
    - Could be useful for interacting with existing hardware designs via cosimulation as well.
  - Injecting/punching ports through modules
    - Tools that punch debug or test ports through hardware hierarchy in SystemVerilog are very complex and difficult to develop, requiring parsing and code generation.  Would be easy with ROHD and an interesting example.

### January 26, 2022 @ 8AM Pacific Time

- Updates, Opens, and Questions
- Random Constraint Solver: discussion and demo
  - Dart package that wraps Microsoft's Z3 SAT solving libraries
  - Useful for ROHD and ROHD-VF, but can be used without them
  - Uses the QuickSampler algorithm to randomize, minimizing number of calls to Z3
  - Supports signed and unsigned numbers
  - Future idea: solve by decomposition, splitting apart sets of variables that are unrelated
  - Could create a dart CLI to give easy access to quicksampler to other applications outside of Dart
  - Investigate direct access between Dart and C++ layer rather than through subprocess calls
  - Plan to open source soon, once testing and documentation are ready

### January 5, 2022 @ 8AM Pacific Time

- Updates, Opens, and Questions
- FSM Abstraction
  - Review ways that FSMs are implemented in other libraries (e.g. <https://github.com/StoneCypher/jssm>) and discuss what a good hardware FSM abstraction would look like.
  - Possible features to include in an FSM for ROHD
    - Automatic diagram generation
      - PlantUML is a good potential option
    - Define paths through a state machine in a single line where the total FSM is the union of all paths, rather than specifying each individual transition and state
  - Sparsity of state machine impacts whether a table or line-by-line approach is better
    - Maybe multiple interfaces for the same backend is the right solution
  - Initially, focus on synchronous state machines, with clock provided to the FSM
  - Definition of states and actions
    - Parameterize so that enums can be used to declare states up front
  - Experimented with what a ROHD API could look like
- Examples and tutorials (did not have time to discuss)
  - What types of examples and tutorials would be most valuable for those getting started with ROHD?
  - Review examples from other options like Chisel and cocotb.

### December 8, 2021 @ 8AM Pacific Time

- Kickoff meeting!
  - Introductions
- Growing the community
  - Twitter handle
    - Nikhil can help acquire this
- Discuss timeslot and frequency
  - Weekly or every 2 weeks, skipping some in the holidays
  - No complaints about 8AM Wednesdays Pacific Time
- ROHD Repository Tour
  - License
  - Contributing guidelines
  - Open Issues
    - Interesting issues
    - Good first issues
  - Pull requests
  - Discussions
  - Actions
  - Wiki
- ROHD-VF
- Current Development
  - Randomized constraint solver
  - Trackers
  - Cosim
  - Power-aware Simulation & UPF generation
- Future Development
  - CIRCT integration
  - Registers & RAL
  - Coverage
  - HLS Integration (High Level Synthesis)
    - HLS tools could be responsible to build something for ROHD to use
    - ROHD could be part of the workflow, composition and configuration, parameterization, of something other than Verilog
    - Input ROHD language is expressive enough for SV, not clear if it is enough for HLS
      - Easy enough for simple operations (e.g. math operations), but is it reasonable for more complex things?
    - Some examples of tools:
      - <https://github.com/google/xls>
      - <https://github.com/cucapra/calyx>
      - <https://github.com/cucapra/dahlia>
  - New Abstractions
    - FSMs
      - An example of FSM abstraction in JavaScript: <https://github.com/StoneCypher/jssm>
  - Benchmarking
  - Assertions
  - Docker containers
  - Clocking
  - Analog & MSV
  - Integration with backend flows
  - Asynchronous designs
- Future agenda topics
  - Work related to ROHD from guest speakers
  - Discussion on what other people are doing in the industry
  - Comparisons of languages and approaches, intersection of usability and functionality, trade-offs in that space
  - Q&A
  - Usage of ROHD, how to design things with ROHD, walk through an existing design
    - Counter is simple, tree is complicated
  - How to make ROHD a pleasure to design with
    - Chisel comes with many examples, but the language doesn't feel nice
  - Tutorials
    - Not just walk through in meeting, but something generated which could be used outside of the meeting
