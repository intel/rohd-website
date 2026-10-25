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
