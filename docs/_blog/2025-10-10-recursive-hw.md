---
title: "Refining Software Algorithms to Hardware Implementations: Recursion"
permalink: /blog/recursive-hw/
last_modified_at: 2025-10-02
author: "Desmond A. Kirkpatrick"
---

As a new way of describing hardware programmatically, ROHD opens up
the world of hardware to design to people with background in
software algorithms. Today, we see a lot of hardware design in
the space of hardware accelerators which are being to speed up
algorithms that already exist in software. It is interesting,
therefore, to consider design patterns that help us transform
traditional software techniques into hardware: a key software
technique to consider is recursion which is often the most natural way
to describe a given computation.

Trees are a key data structure in both software and hardware upon
which recursive algorithms can operate to achieve fast
computation. Yet it is challenging to write recursive tree computation
in traditional hardware description languages. We will consider a
simple recursive algorithm and then a more general hardware tree
generator as two techniques for capturing recursive computation easily
in hardware using ROHD.

## A Pseudo-LRU Algorithm

