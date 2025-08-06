## Running the site locally

To run the site locally, you can just run

```bash
./run_site.sh
```

It will print a message to the console for the address to view the website.

### Requirements

There are some installation requirements to be able to run it locally.

1. Install ruby & build essentials

    ```bash
    sudo apt update
    sudo apt install ruby ruby-dev build-essential
    ```

2. Install bundler

    ```bash
    sudo gem install bundler
    ```

3. Install dependencies

    ```bash
    cd docs/
    bundle install
    ```

    - If you run into a permissions issue, you can try setting `export BUNDLE_PATH=~/.gems`.

## To add a new section for navigation

You are going to need to modified the files above to create a new changes such as delete section, add a new section. However, if you just need to do a simple redirect, you can just modified ``_data/navigation.yml``.

1. ``_data/navigation.yml``
2. ``_config.yml``
3. Add gitignore on the directory ``.gitignore``, since we are going to pull this from the system
