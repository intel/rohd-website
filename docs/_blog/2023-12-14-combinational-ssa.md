---
title: "Procedural Combinational Logic with SSA in ROHD"
permalink: /blog/combinational-ssa/
last_modified_at: 2023-12-15
author: "Max Korbel"
---

ROHD has recently gained a powerful new feature in the [`Combinational.ssa`](https://intel.github.io/rohd/rohd/Combinational/Combinational.ssa.html) constructor for `Combinational`s that allows safer implementations of equivalent `always_comb` logic in SystemVerilog.  This post discusses some of the motivations of the feature and highlights the power gained by using it.

## Some background on `always_comb`

The [`always_comb`](https://www.verilogpro.com/systemverilog-always_comb-always_ff/) in SystemVerilog is a useful construct for describing purely combinational logic (no sequential elements).  Effectively, it lets you write a block of _procedural_ software-like code that represents and compiles into a combinational block of code, assuming you follow some best practices.

For example, you could write some combinational logic like:

```SystemVerilog
always_comb begin
    calculated_value = 8'h5;
    if(some_condition) begin
        calculated_value = 8'd3;
    end
end
```

This code, as you might guess, sets `calculated_value` to 5, unless `some_condition` is high, in which case it sets `calculated_value` to 3. The use of blocking assignments (as is recommended in `always_comb` blocks) makes these statements execute from top to bottom.  While it's easy to see how a digital circuit (e.g. a mux) could do the same thing functionally, one can imagine that you can do some fancier things whose behavior is more easily understood as procedural execution like this.

However, there's something weird here. The `calculated_value` signal is _not_ a software variable; it's a hardware signal!  How does it have multiple values during this "execution", and what do things that depend on `calculated_value` "see" when using it?  It turns out there's all kinds of weird behavior from a simulation perspective, as well as more serious issues of simulation/synthesis mismatch and unexpected behavior around `always_comb` blocks depending on how you write them.

## Crazy `always_comb` behavior

There's some types of logic that can behave in completely unexpected ways in an `always_comb` block.

### Order of Execution & Sensitivity Madness

For example, consider this block:

```SystemVerilog
always_comb begin
  mask = 8'hf;
  b = a & mask;
  mask = 8'h0;
end
```

We set an 8-bit mask to `0x0f`, then assign our output `b` to be &-masked by `mask`, then re-assign `mask` back to `0`.  On first glance, this looks like this logic should be exactly equivalent to this:

```SystemVerilog
assign b = a & mask;
```

And you're (probably) right! It turns out that most simulation _and_ synthesis tools will end up agreeing with you.

However, some lint tools will flag this `always_comb` block for what's called a "write after read" violation, even though this is perfectly legal SystemVerilog, will synthesize and simulate as you expect (probably).  The reason is that he value of `mask` has changed after it's been used in that procedural block of code.

Imagine we rewrite the original design like this:

```SystemVerilog
always_comb begin
  mask = 8'hf;
  b_temp = a_masked;
  mask = 8'h0;
end
assign a_masked = a & mask;
assign b = b_temp;
```

This feels like it should execute pretty much the exact same way as the original design.  All we've done is moved some of the logic and assignments outside of the always_comb block, and if we think about this in terms of hardware then it looks liek the same & operation should exist.

Unfortunately, the SystemVerilog LRM says otherwise!  The rules we need to be aware of to understand the behavior here are:

- The blocking assignments inside the `always_comb` block will execute in order relative to each other.
- The `always_comb` block will "re-execute" to signals referenced within that block (the senstivity list).

There's something subtle missing here: notice that there's no requirement that the `assign` statements update at the "right" time during the `always_comb` block execution. That's right, we can "execute" these lines in pretty much any order as long as the three lines inside the `always_comb` block happen in order relative to each other.  The `assign` statements can happen whenever, including in-between lines within the `always_comb` block, but not necessarily.

For example, this is a legal execution flow (and what most simulators actually end up picking):

| Execution | `a` | `mask` | `b_temp` | `a_masked` | `b` |
|---------|---|------|--------|----------|--|
| `always_comb` `mask=8'hf` | `x` | `8'hf` | `x` | `x` | `x` |
| `always_comb` `b_temp = a_masked` |`x` | `8'hf` | `x` | `x` | `x` |
| `always_comb` `mask=8'h0` | `x` | `8'h0` | `x` | `x` | `x` |
| Testbench pokes `a = 8'hff` | `8'hff` | `8'h0` | `x` | `x` | `x` |
| `assign a_masked = a & mask` <br/> retriggers always_comb | `8'hff` | `8'h0` | `x` | `8'h0` | `x` |
| `always_comb` `mask=8'hf` | `8'hff` | `8'hf` | `x` | `8'h0` | `x` |
| `always_comb` `b_temp = a_masked` | `8'hff` | `8'hf` | `8'h0` | `8'h0` | `x` |
| `always_comb` `mask=8'h0` | `8'hff` | `8'h0` |  `8'h0` | `8'h0` | `x` |
| `assign b = b_temp` | `8'hff` | `8'h0` |  `8'h0` | `8'h0` | `8'h0` |
|

Most vendors try really hard to make simulation and synthesis behavior match exactly (understandably), so this is how it ends up synthesizing as well:

```SystemVerilog
assign b = 8'h0;
```

But as mentioned, it could have executed in a lot of different ways with different results, and all of thise would have been legal according to the SystemVerilog LRM.

[This issue](https://github.com/steveicarus/iverilog/issues/872) discusses a real scenario where this difference caused the same design passed through two different ROHD `Synthesizers` (the SystemVerilog one and the [CIRCT](https://circt.llvm.org/) one) to have different behavior.

### Behavioral and Synthesis Surprises

You can get some really weird surprises out of `always_comb` blocks in terms of what hardware it implies.  For example, suppose we make a `module` that just does an increment on whatever it receives:

```SystemVerilog
module IncrModule(
input logic [7:0] toIncr,
output logic [7:0] result
);
assign result = toIncr + 8'h1;
endmodule : IncrModule
```

Now what do you think this implementation would do?  Suppose you put `3` into input `a`, what would be the output `b`?  How many increment modules would synthesize?

```SystemVerilog
module DuplicateExample(
input logic [7:0] a,
output logic [7:0] b
);
logic [7:0] intermediate;
logic [7:0] result1;
logic [7:0] result2;

IncrModule  incr1(.toIncr(intermediate),.result(result1));
IncrModule  incr2(.toIncr(intermediate),.result(result2));

always_comb begin
  intermediate = a;
  intermediate = result1;
  intermediate = result2;
end

assign b = intermediate;

endmodule : DuplicateExample
```

Notice that we have the same signal fed into both `IncrModule`s, `intermediate`, and yet it seems to have 3 values during "execution" of the `always_comb`.

We declared two incrememnt modules, and yes it actually does synthesize both of them (for the tools tested, at least). The output `b` gets `a + 2` in both simulation and synthesis.

That's pretty weird, but how about this one?

```SystemVerilog
module ReuseExample(
input logic [7:0] a,
output logic [7:0] b
);
logic [7:0] intermediate;
logic [7:0] result;

IncrModule  incr(.toIncr(intermediate),.result(result));

always_comb begin
  intermediate = a;
  intermediate = result;
  intermediate = result;
end

assign b = intermediate;

endmodule : ReuseExample
```

This time we still assign `intermediate` three times, but it's only going into a single instance of `IncrModule`.  And what's more, we're assigning it the same thing two of those times.  You may guess that since we only created _one_ incrementer, it should only synthesize _one_ and thus the result should be `b` gets `a + 1`.  But if you guessed that, you'd be wrong (for the tools tested, at least).  In both simulation and synthesis, you get two incrementers and you still get `b = a + 2`!

## Guarding Against "Write After Read"

While these examples may seem silly and easy to avoid, there are a lot of real bugs (including ones that make it to silicon) which are caused more complex designs that are affected by this type of problem in unobvious ways.

The vendors and open source tools seem to have come to some implicit agreement about how things should execute (independent of the LRM restrictions) so that things are generally consistent, but it's also best practice to just obey the lint violations for "write after read". If you always avoid those lints, then you should be able to avoid these weird behaviors.

In ROHD, the `Combinational` class (maps to `always_comb`) has special simulation-time behavior to catch "write after read" violations. It works by, during execution of a combinational block, keeping track of any signal that is "read" (i.e. used to compute the execution) and flags an issue if it is "written" (i.e. reassigned) later in that same execution.  This is a really powerful check that prevents _any_ of the above situations, or any other similar ones, from simulating without error. This is one of the many ways in which ROHD is significantly stricter (and safer) than SystemVerilog.

## Loss of Usefulness

This is a pretty big restriction on what initially seemed like a super-powerful procedural-software-to-combinational-hardware abstraction!  We've practically limited what we can do to what could have also been behaviorally described with `assign` statements anyways, plus some bells and whistles like `if`/`else` statements.

For example, we'd have to rewrite our first example like this:

```SystemVerilog
always_comb begin
  mask = 8'hf;
  b = a & mask;
  mask_that_isnt_used = 8'h0;
end
```

This also comes with additional overhead to declare extra intermediate signals any time we face a potential "write after read" issue.

This also happens to break a lot of the usefulness of the [`Pipeline`](https://intel.github.io/rohd/rohd/Pipeline-class.html) abstraction in ROHD, since the whole point is that you can move around, split, and combine combinational blocks of code and have it automatically repipeline.  More on this later.

## Static Single-Assignment (SSA) Form

It would be nice if we could still write our combinational logic in a procedural way, with the tools automatically figuring out how to safely implement it.  Changing the SystemVerilog specification and all the tools that implement it would be quite difficult (or impossible).  But with ROHD, we can automate the creation and connectivity of intermediate signals to avoid "write after read" violations.

It turns out that we can borrow something called [Static Single-Assignment (SSA) form](https://en.wikipedia.org/wiki/Static_single-assignment_form) from compiler design to help us.  The Wikipedia article does a pretty good job explaining it, so we won't cover it in detail here.  SSA allows us to rework procedural code such that each variable is "assigned exactly once and defined before it is used", which is exactly what we need.

Let's take a look at some of our examples above to understand how we can use `Combinational.ssa` to avoid "write after read" violations.

### Example 1

The first one can be implemented (originally) like this in ROHD:

```dart
Combinational([
    mask < 0xf,
    b < a & mask,
    mask < 0,
]);
```

With the changes in the ROHD simulator to guard against "write after read", this will fail in simulation.  If we convert this to use `Combinational.ssa`, we can write:

```dart
Combinational.ssa((s) => [
    s(mask) < 0xf,
    b < a & s(mask),
    s(mask) < 0,
]);
```

Here, the type of `s` is a `Logic Function(Logic signal)`.  In English, it's a function which given a `Logic signal` will provide a different `Logic`.  This is our remapping function allowing us to write our procedural code with a single signal as reference (`mask`).  When ROHD builds the actual logic, it will swap the signal to implement SSA.  We can use the result from calling `s` anywhere we could use any other `Logic` (e.g. passed to a another `Module`) for the purposes of generating our `Combinational`.  Let's take a look at the generated SystemVerilog from ROHD for this block:

```SystemVerilog
always_comb begin
  mask_0 = 8'hf;
  b = (a & mask_0);
  mask = 8'h0;
end
```

Note that it has automatically mapped `s(mask)` to two different "mask" signals (`mask` and `mask_0`) such that we're getting the intent of our combinational logic.  This generated code is lint clean and safe from any associated simulation/synthesis mismatches.

### Example 2

We can do something similar with one of our other examples.  Originally,

```dart
Combinational([
    intermediate < a,
    intermediate < IncrModule(intermediate).result,
    intermediate < IncrModule(intermediate).result,
]);

b <= intermediate;
```

This one will fail in simulation due to "write after read" violations.  Reimplemented with SSA:

```dart
Combinational.ssa((s) => [
    s(intermediate) < a,
    s(intermediate) < IncrModule(s(intermediate)).result,
    s(intermediate) < IncrModule(s(intermediate)).result,
]);

b <= intermediate;
```

which generates:

```SystemVerilog
module DuplicateExampleSsa(
input logic [7:0] a,
output logic [7:0] b
);
logic [7:0] intermediate;
logic [7:0] result;
logic [7:0] result_0;
logic [7:0] toIncr;
logic [7:0] toIncr_0;

IncrModule  incr(.toIncr(toIncr),.result(result));
IncrModule  incr_0(.toIncr(toIncr_0),.result(result_0));

always_comb begin
  toIncr = a;
  toIncr_0 = result;
  intermediate = result_0;
end

assign b = intermediate;

endmodule : DuplicateExampleSsa
```

Again, notice that the SSA has taken care of renaming signals.  It is unambiguous what signals are feeding into which increment and what the final result `b` will be.  The ROHD simulation will work as expected now, and the generated SystemVerilog matches the intent for simulation and synthesis.

### Example 3

Let's take a look at the third example as well, which only had one incrementer.  Originally in ROHD,

```dart
final inc = IncrModule(intermediate);

Combinational([
  intermediate < a,
  intermediate < inc.result,
  intermediate < inc.result,
]);

b <= intermediate;
```

With ssa:

```dart
final inc = IncrModule(intermediate);

Combinational.ssa((s) => [
  s(intermediate) < a,
  s(intermediate) < inc.result,
  s(intermediate) < inc.result,
]);

b <= intermediate;
```

Which generates:

```SystemVerilog
module ReuseExampleSsa(
input logic [7:0] a,
output logic [7:0] b
);
logic [7:0] intermediate;
logic [7:0] intermediate_0;
logic [7:0] intermediate_1;
logic [7:0] result;

IncrModule  incr(.toIncr(intermediate),.result(result));

always_comb begin
  intermediate_0 = a;
  intermediate_1 = result;
  intermediate = result;
end

assign b = intermediate;

endmodule : ReuseExampleSsa
```

We have avoided the "write after read" issue here, however it now looks very clear that we have a single incrementer where the output is fed directly back into the input. In the ROHD simulation, this is a combinational loop and you'll get `x` on the affected signals. It turns out SystemVerilog simulators (again, the ones tested, at least) also will simulate this with `x` generation due to the combinational loop.

## ROHD `Pipeline`s and SSA

Recall that a `Pipeline` in ROHD is an abstraction that enables easy refactoring of combinational logic across stages.  A toy example is incrementing by 1 three times, once per cycle, is shown here:

```dart
Pipeline(clk, stages: [
  (p) => [p.get(a) < p.get(a) + 1],
  (p) => [p.get(a) < p.get(a) + 1],
  (p) => [p.get(a) < p.get(a) + 1],
]);
```

The `Combinational.ssa` is plugged right into the abstraction automatically (notice that `p.get` usage in `Pipeline` and `s` usage in `Combinational.ssa` look similar).

We can refactor this to do them all in one cycle without rewriting any logic:

```dart
Pipeline(clk, stages: [
  (p) => [
        p.get(a) < p.get(a) + 1,
        p.get(a) < p.get(a) + 1,
        p.get(a) < p.get(a) + 1,
      ],
]);
```

We're reassigning the same variable multiple times and reusing it.  Actually, even with just a single increment we're already doing a "write after read".  This API takes care of using SSA to safely construct the pipeline hardware as intended.

## Conclusion

The `always_comb` behavior discussed in this post is just one of many examples where SystemVerilog's behavior in simulation and synthesis can be confusing and unpredictable.  Lint checks are a band-aid.  These language issues harm hardware development productivity.

The `Combinational.ssa` in ROHD is one of many examples where developing hardware with ROHD is stricter, safer, and more powerful.  Try it out if you haven't yet!

