---
title: "A Flutter UI Debugger for ROHD"
permalink: /blog/announcing-rohd-devtool-extension/
last_modified_at: 2024-05-08
author: "Yao Jing Quek"
---

When you hear the term "Flutter", your mind might instantly associate it with native mobile app development. However, Flutter's capabilities extend far beyond that. Not only is it a powerful framework for mobile app design, but it also allows for a single codebase for desktop, web, iOS, and Android development. Today, we're going to explore how Flutter can be used as a debugger for a Hardware Design Framework Tool - ROHD.

## What is ROHD?

ROHD, or Rapid Open Hardware Development Framework (<https://intel.github.io/rohd-website/>), is a framework for hardware generation and design using the Dart programming language. Yes, you read that right - Dart, the same language used by Flutter for development. ROHD offers the flexibility to develop your hardware using modern languages and software practices, resulting in a cleaner and more powerful library.
But why did ROHD choose Dart? The answer lies in Dart's potential and the features it offers. Dart's Futures allow for efficient simulation, and its low learning curve means you can become proficient in less than a week. Furthermore, Dart's object-oriented design, excellent community support, and the ability to build EDA tools on top of it make it an ideal choice for ROHD. The results and testing shown that efficiency, performance, and engineer productivity have achieved significant gains by using ROHD, as detailed in the <https://woset-workshop.github.io/WOSET2022.html>. You can watch the video explaining this at <https://www.youtube.com/watch?v=ahF6MRJKLVw> as well!

## Flutter + ROHD: A powerful combination

At the time of writing this article, ROHD has adopted a beta version of a debugger built using Flutter. The full capabilities and proposal of the debugger are detailed in this discussion <https://github.com/intel/rohd/discussions/418>, which started with the hierarchy viewer as the proof of concept (POC) for the development.
This implementation allows for a seamless experience where users can design and debug simultaneously. Users can step through the VSCode debug points and instantly see the value changes over time in each clock cycle. This feature serves as the foundation for other tools to be designed and built using Flutter.

## Flutter’s Devtool Extension

We owe a great deal of gratitude to the Google Flutter Team for introducing the devtool extension feature. This feature allows us to create an extension that binds with the existing Flutter extension. It came at a time when we needed it the most, and we are thankful to the team for their support and for arranging a meeting to clarify our requirements.
The concept is straightforward: we have a Flutter front-end that serves as the UI for users to interact with. We then use the Flutter devtools extension to communicate with the Dart Virtual Machine to retrieve data such as the variables when the breakpoints hit, and so on. All of this is done using the package service manager. You can find the complete code at <https://github.com/intel/rohd/tree/main/rohd_devtools_extension>.

Everything written here is open-source and we welcome everyone to be the early contributor, adopter or even provides feedbacks to us!
