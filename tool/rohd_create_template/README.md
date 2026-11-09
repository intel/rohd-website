# ROHD Create Template Source

This directory is the source for the downloadable ROHD Create bundles.

- `starter/` is the editable source of the generated Dart package.
- `rohd_create.sh` and `rohd_create.ps1` validate the host system, extract
  `starter.tar.gz`, substitute package/module/version placeholders, and run
  Pub when requested.
- `../build_rohd_create_bundles.py` packages the starter as `starter.tar.gz`
  and emits one Linux/WSL ZIP and one Windows ZIP under
  `docs/assets/downloads/`.

Do not edit generated ZIP files. Edit `starter/` or a platform launcher, then
run:

```sh
python3 tool/build_rohd_create_bundles.py
```

The bundle tests verify both archive contents and extracted-launcher behavior.

## Integration tests

With Dart >=3.6.0 and <4.0.0 and Python 3 installed, run from the repository root.

Linux (requires `tar` and `unzip`):

```sh
bash tool/test/rohd_create_integration_test.sh
```

Windows (requires PowerShell and `tar`):

```powershell
./tool/test/rohd_create_integration_test.ps1
```

Each test builds and extracts its platform's bundle, runs the launcher to create
a package in a temporary `test/` directory, and runs `dart analyze` and
`dart test` in that package. The package is named `my_first_module` to avoid
conflicting with its `test` dependency. Temporary files are cleaned up on exit.
Both the General and Pages workflows run these tests on Linux and Windows.
