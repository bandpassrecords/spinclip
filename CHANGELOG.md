# Changelog

## v0.2.0 — 2026-09-28

### Highlights
- **Easy path by default, Advanced mode on request** — the wizard opens to a minimal four-step
  flow (Release type, Files, Platforms, Review & render), with every visualizer/customize/
  duration/output setting using its existing sensible default. A toggle reveals the full set of
  steps for people who want to tweak them.
- **Split-screen wizard** — options on the left, a persistent live preview on the right, updated
  on every step instead of only a couple of them. The preview panel also now carries a category
  summary (with jump-straight-there edit links), visible from any step rather than only at the end.
- **Templates** — save the current style (visualizer, colors, overlays, platforms, performance
  settings) as a named, disk-persisted template and reload it later via a combo box, so the same
  look can be reused across releases without redoing every setting for a new cover/song.
- **Batch releases with per-track covers** — multi-song/medley tracks can each supply their own
  cover image (with a thumbnail in the track list) instead of sharing one, so a single batch can
  mix different covers; multi-select file picking lets you add several songs at once.
- **Internationalization** — English, Portuguese, and Spanish, with a language switcher (plus a
  "System" option) in the title bar.
- **Custom cross-platform title bar** replacing the native one, with window controls on
  Windows/Linux and traffic-light-safe spacing on macOS.
- **Visualizer color picker** — a swatch palette plus Auto (extracted from the cover image),
  Dark, and Sparkling quick themes; the audio excerpt preview's waveform now matches the chosen
  color instead of a fixed white.
- **Mild vintage/aging frame effect** — warm tint, soft vignette, light film grain, blended at
  partial strength.
- **Platform brand icons** on the platform picker, and an Advanced-mode custom resolution
  override per selected platform (with reset-to-default).
- **Illustrated release-mode picker** — radio tiles with a small icon diagram (cover + song count
  → video count) showing at a glance what single/multi-song/medley actually produce.
- **Per-release output folder + overwrite confirmation** — each render now writes into a
  subfolder named after the cover image (or a typed override) so different releases don't
  collide, with a confirmation dialog if the target folder already has files in it.
- **Required-field validation** — the wizard won't let you past the Files step without a cover
  image and audio (or, in batch mode, tracks that each resolve one).
- **ffmpeg/ffprobe are now bundled** for Windows and macOS — end users no longer need to install
  anything themselves on those platforms.
- **Windows MSIX packaging**, built and uploaded alongside the existing zip in CI.

### Fixes
- The QR code overlay wasn't appearing in the live preview (only in the final render) - the
  preview now generates the same QR asset the render pipeline does.
- The audio excerpt preview's play button could hang for 30 seconds and throw, if the very first
  press needed to seek before any audio source had ever been loaded.

### Known gaps
- Linux still relies on a system ffmpeg install on `PATH` — Windows and macOS bundle their own.
- The macOS ffmpeg bundling (a new Xcode Run Script build phase) hasn't been verified on an
  actual Mac yet; it was authored and only build-tested on Windows.
- The Windows MSIX is unsigned (`store: true` defers signing to a future Store submission) and
  its `publisher` identity is inherited from the `daw-project-manager` sibling project's Partner
  Center account — worth confirming before a real submission.

---

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
