# Contributing to the ROHD Website

Thank you for considering contributing to the ROHD Website! Contributions from the community are vital to making this a successful project.

Anyone interested in participating in ROHD is more than welcome to help!

## Code of Conduct

The ROHD website adopts the [Contributor Covenant](https://www.contributor-covenant.org/) v2.1 for the code of conduct. It can be accessed [here](CODE_OF_CONDUCT.md).

## Getting Help

### Chat on Discord

[Discord](https://discord.com/) is a free online instant messaging app which you can use directly in your web browser or install to your device. Feel free to join to look around at the conversations and have a real-time discussion with the ROHD community. This a great place to ask questions, get help, engage with the rest of the community, and discuss new ideas.

Join the Discord server here: <https://discord.com/invite/jubxF84yGw>

### GitHub Discussions

GitHub Discussions is a place where you can find announcements, ask questions, share ideas, show new things you're working on, or just discuss in general with the community! If you have a question or need some help, this is a great place to go.

You can access the discussions area here: <https://github.com/intel/rohd-website/discussions>

### GitHub Issues

If something doesn't seem right or something is missing then filing an issue on the GitHub repository is a great option. Please try to provide as much detail as possible.

You can file an issue here: <https://github.com/intel/rohd-website/issues/new/choose>

### Meetings in the ROHD Forum

The [ROHD Forum](https://intel.github.io/rohd-website/forum/rohd-forum/) is a periodic virtual meeting for developers and users of ROHD that anyone can join. Feel free to join the call!

## Getting Started

### Setup Recommendations

#### On your own system

[Visual Studio Code (VSCode)](https://code.visualstudio.com/) is a great IDE for development. You can find installation instructions for VSCode here: <https://code.visualstudio.com/Download>

#### In GitHub Codespaces

[GitHub Codespaces](https://github.com/features/codespaces) are a great feature provided by GitHub allowing you to get into a development environment based on a pre-configured container very quickly! You can use them for a limited number of hours per month for free. The ROHD website repository has set up GitHub Codespaces so that you can immediately start editing in your browser without installing anything.

The below button will allow you to create a GitHub Codespace with the ROHD website already cloned and ready to roll:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=619988491)

### Cloning and Running the Tests

Once requirements are installed, you can clone and run the test suite:

```shell
git clone https://github.com/intel/rohd-vf.git
cd rohd-vf
dart pub get
dart test
```

## How to Contribute

### Reporting Vulnerabilities

Please report any vulnerabilities according to the information provided in the [SECURITY.md](SECURITY.md) file.

### Reporting Bugs

Please report any bugs you find as a GitHub issue. Please try to provide as much detail as possible. Complete, stand-alone reproduction instructions are extremely helpful for bugs!

Some helpful information you can include:

* Output of `dart --version`
* Your dependencies from `pubspec.yaml`
* The version of ROHD and ROHD-VF you're using
* Command you ran and output
* Reproduction code and steps

### Suggesting Enhancements

If you have an idea for a feature or enhancement that would make ROHD better, feel free to submit a GitHub issue! Discussion on the ticket about pros & cons, strategy, etc. is encouraged.

### Discussing Issues

If you have an opinion or helpful information on any open issue, feel free to comment! Even if you don't have the time to implement a change, providing valuable input is great too!

### Fix or implement an Issue

Take a look around the issues on the repo and see if there's any you'd like to take ownership of. For your first contributions, look for issues tagged with `good first issue`, which are intended to be easier to get started with. Feel free to ask for help or guidance!

### Pull Requests

If you have a change that you have implemented and would like to contribute, you can open a pull request. Please try to make sure you have implemented tests covering the changes, if applicable. Smaller, simpler pull requests are easier to review.

**Tests must pass, documentation must generate, and the formatter must be run on every pull request or the automated GitHub Actions flow will fail.**

Maintainers of the project and other community members will provide feedback and help iterate as necessary until the contribution is ready to be merged.

Please include the SPDX tag near the top of any new files you create:

```dart
// SPDX-License-Identifier: BSD-3-Clause
```
