---
title: Troubleshooting
description: What to do when Spinclip won't open, can't find FFmpeg, or a render fails.
---

## Windows says "Windows protected your PC"

Spinclip isn't code-signed yet. Choose **More info**, then **Run anyway**.

## macOS says Spinclip can't be opened

Spinclip isn't notarized by Apple yet. Open **System Settings → Privacy & Security** and click **Open Anyway** next to the message about Spinclip. On Apple silicon, accept the offer to install Rosetta if it appears — the bundled FFmpeg needs it.

## "ffmpeg was not found"

Spinclip looks for FFmpeg in this order:

1. the copy that comes with the app (Windows and macOS);
2. the folder in the `FFMPEG_PATH` environment variable;
3. your `PATH`.

On **Linux**, install FFmpeg from your distribution (see [Installation](/guide/installation/#linux)). Elsewhere, reinstalling Spinclip restores the bundled copy.

## The preview says "Select a cover image and audio first"

The preview needs a cover and a song — for several songs, at least one song whose cover is set (its own or the default).

## "Couldn't read this file"

The audio file isn't one FFmpeg can read, or it's damaged. Try exporting it again as WAV or FLAC.

## A render is slow

- Check that **Hardware-accelerated encoding** is on ([Output & performance](/guide/output/)).
- Render an [excerpt](/guide/duration/) instead of the full song while you try looks out.
- Each ticked platform is a separate video: untick the ones you don't need yet.

## Something else

[Open an issue on GitHub](https://github.com/bandpassrecords/spinclip/issues) with what you did, what you expected, and what happened — the error message, if there was one.
