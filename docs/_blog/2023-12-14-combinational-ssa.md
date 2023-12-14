---
title: "Procedural Combinational Logic with SSA in ROHD"
permalink: /blog/combinational-ssa/
last_modified_at: 2023-12-14
author: "Max Korbel"
---

<!-- 
Outline:
- Background on always_comb
- Example of some crazy behavior
- Adding guard to fix it
- But now we lost the always_comb benefits! (+ pipelining)
- Add SSA, how it works 

PROBLEMS:
- scope of execution is variables referenced
- order of execution is non-determinsitic

LINT check catches

-->

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

There's some types of logic that behave in completed unexpected ways in an `always_comb` block.

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

This time we still assign `intermediate` three times, but it's only going into a single instance of `IncrModule`.

## Loss of usefulness

The vendors and open source tools seem to have come to some implicit agreement about how things should execute (independent of the LRM restrictions) so that things are generally consistent, but it's also best practice to just obey the lint violations for "write after read". If you always avoid those lints, then you should be able to avoid these weird behaviors.

However, this is a pretty big restriction on what initially seems like a super-powerful procedural-code-to-combinational-logic abstraction!  We've practically limited what we can do to what could have also been behaviorally described with `assign` statements anyways, plus some syntactic sugar like `if`/`else` statements.
