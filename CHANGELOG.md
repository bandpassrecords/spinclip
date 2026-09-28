# Changelog

## v0.1.0 — 2026-09-28

### Highlights
- **Initial release** — generate a promo video from a cover image and a song: blurred/stretched background, sharp cover overlay, and an FFmpeg-rendered audio-reactive visualizer.
- **CLI and GUI share one core** — `bin/render_cli.dart` and the Flutter desktop app both drive the same `filtergraph_builder`/render services, so a command built for one behaves identically in the other.
- **Six visualizer placements × four styles** — bottom band, side border, dual-mirrored-bottom, full-frame border, ascending corner, and centered-behind-text, each combinable with bars, line spectrum, fluid wave, or oscilloscope.
- **Optional cover, logo, and text overlays**, plus a configurable cover-size knob and a live pixel-accurate preview.
- **Seven platform export presets**, including Spotify Canvas's fixed short-loop duration, with full-duration-by-default trimming that can be switched to a manual start/duration range.
- **Multi-song batch mode** — render one independent output video per song, across every selected platform.
- **Medley mode** — combine a trimmed excerpt from each song into a single video per platform, for promoting a multi-track release.
- **Lossless PCM audio by default** and **automatic hardware-accelerated encoding** (NVENC/Quick Sync/AMF/etc.) with a software fallback.

---

### Known gaps
- No in-app waveform preview yet (planned; the sibling `daw_project_manager` project's peak-extraction code is a candidate to adapt).
- macOS/Linux ffmpeg bundling relies on a system install on PATH; only Windows bundles a local binary lookup path today.
