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

## Adding Videos

Short videos can be hosted directly by this GitHub Pages site. Prefer MP4
containing H.264 video and AAC audio for broad browser compatibility.

### Prepare the Video

Install FFmpeg, then move the MP4 metadata to the beginning of the file. This
is known as "fast start" and lets browsers begin playback without downloading
the entire video first.

```bash
sudo apt install ffmpeg
ffmpeg -i input.mp4 -map 0 -c copy -movflags +faststart output.mp4
```

This operation changes the container metadata without re-encoding the video.
Keep the input until the output has been validated. If the original file has
already been served, publish the optimized file under a new filename and
update the post. Reusing the URL can cause a browser to combine cached byte
ranges from the old and new container layouts, resulting in stalled playback.

Check the codecs, pixel format, duration, and resolution:

```bash
ffprobe -v error \
  -show_entries format=duration,size:stream=codec_name,profile,width,height,pix_fmt \
  -of default=noprint_wrappers=1 output.mp4
```

For maximum compatibility, expect `h264`, `aac`, and `yuv420p`. Verify that the
complete file decodes without errors:

```bash
ffmpeg -v error -i output.mp4 -f null -
```

If the input is not already compatible, re-encode it:

```bash
ffmpeg -i input-video \
  -c:v libx264 -profile:v main -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart output.mp4
```

### Add the Video to a Blog Post

Use a lowercase filename and store the video alongside the other site assets:

```text
assets/videos/<post-name>/<video-name>.mp4
```

Embed it with native browser controls. A poster avoids an empty player while
the metadata loads:

```html
<video controls="controls" playsinline="playsinline" preload="metadata"
    poster="{{ site.baseurl }}/assets/images/<post-name>/<poster>.png"
    style="display: block; width: 100%; height: auto;">
  <source
      src="{{ site.baseurl }}/assets/videos/<post-name>/<video-name>.mp4"
      type="video/mp4">
  Your browser does not support embedded video.
  You can <a href="{{ site.baseurl }}/assets/videos/<post-name>/<video-name>.mp4">download the video</a> instead.
</video>
```

Do not use `autoplay`; visitors should choose when playback begins. If the
video contains narration or other essential audio, provide captions or a
transcript.

If the video replaces a screenshot of the same initial view, use that
screenshot as the poster instead of displaying both.

### Preview and Validate

Jekyll excludes future-dated posts by default. Include `--future` when
previewing scheduled posts:

```bash
cd docs/
./run_site.sh
```

The script includes future posts, binds to all IPv4 interfaces for remote
development, and applies a local WEBrick range-request compatibility fix.
Specify a different port when needed:

```bash
./run_site.sh --port 4001
```

Confirm that the page loads, the controls appear, playback starts, seeking
works, and the browser can enter fullscreen. Also confirm that the server
supports byte-range requests:

```bash
curl -D - -o /dev/null \
  -H "Range: bytes=0-1023" \
  http://127.0.0.1:4000/assets/videos/<post-name>/<video-name>.mp4
```

A working response is `206 Partial Content` with a `Content-Range` header and
`Content-Type: video/mp4`.

The local workaround is still required with WEBrick 1.9.2. A matching
`If-Range` ETag must return `206` with the requested bytes; a stale ETag must
return `200` with the full file. The upstream fix is tracked in
[ruby/webrick#173](https://github.com/ruby/webrick/pull/173).

Run the regression checks from `docs/` (also run by the site's CI):

```bash
bundle exec ruby tool/test_webrick_range_fix.rb
```

After the upstream fix is released, run the same command with
`--without-workaround` to check whether the patch can be removed. That mode
is expected to fail on WEBrick 1.9.2. The checks use a temporary local file
and a loopback-only server on an automatically allocated port.

The production workflow intentionally does not use `--future`, so scheduled
posts are not published before their filename date. Static video assets may
be deployed before the post that references them.

### GitHub Pages and Repository Limits

Keep videos short and compressed. GitHub Pages has a recommended 1 GB source
repository limit, a 1 GB published-site limit, and a soft 100 GB monthly
bandwidth limit. GitHub warns about individual repository files larger than
50 MiB and blocks files larger than 100 MiB. Avoid Git LFS for small website
videos because the checked-in MP4 should be present in the generated Pages
artifact.

### Videos in GitHub README Files

GitHub README rendering is different from GitHub Pages. GitHub sanitizes an
external Pages URL used as a `<video>` source. Use a GitHub-hosted attachment:

1. Create the GitHub repository.
2. Drag the prepared MP4 into an issue, pull request, or discussion editor.
3. Copy the generated `https://github.com/user-attachments/assets/...` URL.
4. Add it to the README:

   ```html
   <video controls src="https://github.com/user-attachments/assets/<id>"></video>
   ```

GitHub accepts MP4, MOV, and WebM attachments and recommends H.264 for browser
compatibility. Video uploads are limited to 10 MB for repositories on a free
plan and 100 MB for repositories on a paid plan.

## To add a new section for navigation

You are going to need to modified the files above to create a new changes such as delete section, add a new section. However, if you just need to do a simple redirect, you can just modified ``_data/navigation.yml``.

1. ``_data/navigation.yml``
2. ``_config.yml``
3. Add gitignore on the directory ``.gitignore``, since we are going to pull this from the system
