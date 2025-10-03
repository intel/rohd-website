---
title: "Refining Software Algorithms to Hardware Implementations: Recursion"
permalink: /blog/recursive-hw/
last_modified_at: 2025-10-02
author: "Desmond A. Kirkpatrick"
---

As a new way of describing hardware programmatically, ROHD opens up
the world of hardware design to people with background in software
algorithms. Today, we see a lot of hardware design in the space of
hardware accelerators which are being used to speed up algorithms that
already exist in software. It is interesting, therefore, to consider
design patterns that help us transform traditional software techniques
into hardware: a key software technique to consider is *recursion* which
is often the most natural way to describe a given computation.

Trees are a key data structure in both software and hardware upon
which recursive algorithms can operate to achieve fast
computation. Yet it is challenging to write recursive tree computation
in traditional hardware description languages. We will consider a
simple recursive algorithm and then a more general hardware tree
generator as two techniques for capturing recursive computation easily
in hardware using ROHD.

## A Pseudo-LRU Algorithm

Set-associative caching requires a replacement policy to figure out
which 'way' in the cache to evict data from in order to store new
data. Least Recently Used (LRU) algorithms require a very complex
history mechanism to compute exactly, so an approximation is often
used called 'pseudo-LRU'. 

To compute the least-recently-used 'way', a pseudo-LRU algorithm uses
a binary tree with 'ways' as leaves, where a '0' at an intermediate
node indicates the LRU 'way' is to the right and a '1' indicates the
LRU 'way' is to the left. In the figure below, we can see that 'way'
'5' is LRU according to the current settings at each node of the tree.

![plru]({{site.baseurl}}/assets/images/plru.png)

Two routines are needed to maintain the PLRU tree above in order to do
pseudo-LRU computation, first for finding the LRU `way` to 'allocate' a
new entry and the other for updating the LRU state as `way`s are 'hit'
by reads or writes.

## PLRU Allocation

### Software PLRU Allocation

It is quite natural to describe the allocation on the PLRU tree in a
recursive routine. Here we show the routine written in software that,
given the state of the PLRU tree as a list of 0/1 values returns an
the integer LRU `way`. This state vector is stored from the tree nodes
as seen from left-to-right.

```dart
 1 int allocPLRU(List<int> v, {int base = 0}) {
 2   final mid = v.length ~/ 2;
 3   return v.length == 1
 4       ? v[0] == 1
 5           ? base
 6           : base + 1
 7       : v[mid] == 1
 8           ? allocPLRU(v.sublist(0, mid), base: base)
 9           : allocPLRU(v.sublist(mid + 1, v.length), base: mid + 1 + base);
10 }
```
Here you can see that the recursion splits on the middle element of a
0/1 vector at line 7, searching left if the node has a '1' otherwise
searching right. At the leaf (line 4) it returns the left element if
the node is '1' otherwise the right element as the LRU `way`.

### Hardware PLRU Allocation

ROHD allows us to describe the LRU allocation algorithm recursively in
hardware as well because it allows us to generate hardware recursively
for the tree.

In the hardware algorithm below, we see that we pass in a bitvector in
the form of `Logic` and again split on the middle element of the
vector (line 5). Instead of a ternary operation (lines 4-6 of the
software algorithm above), we can use a `mux` (line 8 below) on the
middle element value to return the result of the left recursion or
right recursion.  At the leaf (line 7), we can `mux` on the node to
return the left element in case of a '1' otherwise the right element.

```dart
 1 Logic allocPLRU(Logic v, {int base = 0, int sz = 0}) {
 2   final lsz = sz == 0 ? log2Ceil(v.width) : sz;
 3   Logic convertInt(int i) => Const(i, width: lsz);
 4
 5   final mid = v.width ~/ 2;
 6   return v.width == 1
 7       ? mux(v[0], convertInt(base), convertInt(base + 1))
 8       : mux(
 9            v[mid],
10  _         allocPLRU(v.slice(mid - 1, 0), base: base, sz: lsz),
11  _         allocPLRU(v.getRange(mid + 1),
12  _             base: mid + 1 + base, sz: lsz));
13 }
```
## PLRU Hit/Invalidate

A second algorithm needed to maintain the PLRU tree is to manage
'hits' to a given `way`, making that `way` 'recently used', or to
invalidate a `way`, making it available for use and marking it as
LRU. Given a `way` to hit or invalidate, this algorithm needs to
update the state of the PLRU tree and return it.

### Software PLRU Hit/Invalidate

For the software form of the hit algorithm, the PLRU state is again
traversed recursively, splitting on the middle element (line 6) and
processing the lower and upper portions of the state vector.  If the
`way` being hit is in the left portion, then that portion of the tree is
processed, otherwise it is simply returned -- similarly for the right.

```dart
 1 List<int> hitPLRU(List<int> v, int way,
 2     {int base = 0, bool invalidate = false}) {
 3   if (v.length == 1) {
 4     return [if ((way == base) == invalidate) 1 else 0];
 5   } else {
 6     final mid = v.length ~/ 2;
 7     var lower = v.sublist(0, mid);
 8     var upper = v.sublist(mid + 1, v.length);
 9     lower = (way <= mid + base)
10         ? hitPLRU(lower, way, base: base, invalidate: invalidate)
11         : lower;
12     upper = (way > mid + base)
13         ? hitPLRU(upper, way, base: mid + base + 1, invalidate: invalidate)
14         : upper;
15     final midVal = ((way <= mid + base) == invalidate) ? 1 : 0;
16     return [...lower, midVal, ...upper];
17   }
18 }
```

Let's consider the 'hit' case where `invalidate` is false. Then at
split point, the middle value (line 15) is set to '0' if the `way` is
left or same as the middle, and it is set to '1' if the `way` is to
the right, both indicating the LRU is in the opposite direction. The leaf
processing (line 4) is similar: if we match the `way` at the node,
then set the node to '0' to switch LRU away from this leaf, otherwise
set to '1' to indicate that LRU is this node (remember '0' indicates
the LRU direction).

If we consider the `invalidate` true case, the logic is simply
reversed: a hit means LRU is going in this direction and wherever we
would have set a '0', we would set a '1' instead to invalidate and
vice-versa. Invalidate forces the tree nodes to follow the final way
with a series of '0s'.

### Hardware PLRU Hit/Invalidate

The hardware recursion for PLRU hit/invalidate follows the same
pattern as software. Yet because we need to pass back the entire state
vector, not knowing the actual value of `way` at generation time, we
need to fully process each element of the vector with the `way` in the
algorithm. That can be seen most clearly in the upper and lower
recursions (lines 13 and 14) where we must invoke the recursive
routine for both directions so that the `way` signal is generated into
both sides of the tree at each node to be compared appropriately in
hardware since it is a dynamic signal that changes after hardware
generation. Remember in software we knew the value of `way` so we
could just return the left or right portion unprocessed.

```dart
 1 Logic hitPLRU(Logic v, Logic way,
 2     {int base = 0, Logic? invalidate}) {
 3   Logic convertInt(int i) => Const(i, width: way.width);
 4 
 5   invalidate ??= Const(0);
 6   if (v.width == 1) {
 7     return mux(way.eq(convertInt(base)), invalidate,
 8         mux(way.eq(convertInt(base + 1)), ~invalidate, v[0]));
 9   } else {
10     final mid = v.width ~/ 2;
11     var lower = v.slice(mid - 1, 0);
12     var upper = v.getRange(mid + 1);
13     lower = hitPLRU(lower, way, base: base, invalidate: invalidate);
14     upper = hitPLRU(upper, way, base: mid + base + 1, invalidate: invalidate);
15     final midVal = mux(
16         way.lt(convertInt(base)) | way.gt(convertInt(base + v.width)),
17         v[mid],
18         mux(way.lte(convertInt(mid + base)), invalidate, ~invalidate));
19     return [lower, midVal, upper].rswizzle();
20   }
21 }
```

At the split point (line 15), we compare the `way` to the range of the
current subtree to ensure it is within that range. If not we simply
return the midpoint value (line 17) unchanged. This is one situation
in which hardware recursion differs from software that we need to
check this condition which adds range comparison at every node.

Otherwise, in the 'hit' case (`invalidate` is false), we return '1' if the `way`
is in the left subtree and '0' if it is in the right (line 18).

Finally, we return a concatenation of the computed PLRU state vector
(line 19).  Again note that the `invalidate`=true case simply reverses
them meaning of '1' and '0'.

We can see that maintaining a PLRU tree to support pseudo-LRU
computation is quite similar in both software and hardware recursive
forms. ROHD makes it simple to follow software patterns to generate
hardware naturally when the computation is easily described
recursively.

## A Reduction Tree Component

A reduction is an efficient arrangement of computation of associative
operations (like sum or max) to compute a single result from an array
of inputs.

Reductions are common in both software and hardware and improve the
latency of computation logarithmically by arranging a tree of
computation to perform parallel operations even when the output is a
single result. 

In Hardware Description Languages (HDL)s, there is even syntax to
perform common bit-level reductions like or-reduction and
and-reduction. It is more difficult to describe reductions on more
complex inputs or operations in traditional HDLs.

Yet in software, more complex reduction trees are possible because of
the compositional nature of software languages. For example the C++
Standard Template Library (STL) contains a template operator
`std::reduce` to perform reduction generically on STL
containers. Indeed, these operations are threaded to ensure fastest
possible execution in reduction tree arrangements within STL.

To perform more complex reductions in hardware, the [ROHD Hardware
Component Library (HCL)](<https://github.com/intel/rohd-hcl>) provides
a `ReductionTree` component which takes an associative operation and
populates a hardware tree arrangement to compute a hardware reduction
with a latency that is logarithmic with the number of inputs. In
hardware we need to consider pipelining as well for any significant
reduction length.

### Add Reduction Tree

Here is an example of a reduction tree using the native add operations
of SystemVerilog, but written using a ROHD generator class. 

On lines 1-3 is the operation to be instantiated by tree generator, in
this case a native addition of two inputs.

On lines 9-10 is the tree generation, producing a radix-4 tree of
these 79 13-bit inputs and adding pipelining at every other level of
adders.

```dart
 1  Logic addReduce(List<Logic> inputs,
 2          {int depth, Logic? control, String name = ''}) =>
 3       inputs.reduce((v, e) => v + e);
 4   /// Tree reduction using addReduce
 5     const width = 13;
 6     const length = 79;
 7     final vec = <Logic>[];
 8
 9     final reductionTree = ReductionTree(
10         vec, radix: 4, addReduce, clk: clk, depthBetweenFlops; 2);
```

It would be quite simple to do other operations like `max` or `min` or operate on
other datatypes like `FloatingPoint` or `FixedPoint`.

By replacing the operator `addReduce` with more complex hardware
generators, we can also generate more complex tree reduction
computations in hardware.

## Mux Reduction Tree

Here is a more complex example (similar to reduction) that passes in a
control line that can be indexed by the depth of the tree to perform a
muxing operation, an operation quite useful in hardware:

```dart
    const length = 1024;
    final width = log2Ceil(length);
    final vec = <Logic>[];
    final control = Logic(width: log2Ceil(vec.length)));

    Logic muxReduce(List<Logic> inputs,
        {int depth, Logic? control, String name = 'mux'}) =>
      mux(control![depth], inputs[1], inputs[0]);

    final muxTree = ReductionTree(vec, muxReduce,
        clk: clk, depthBetweenFlops: 2, control: control, name: 'mux');
```

Being able to quickly generate tree reductions is another way to map
what are common software design patterns into hardware with a high
degree of control over the performance of that hardware.
