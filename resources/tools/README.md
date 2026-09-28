# Bundled tools

Spinclip's entire rendering pipeline shells out to ffmpeg/ffprobe (see
`FiltergraphBuilder` and `AudioProbeService`) - unlike a media player, there's
no OS-native fallback, so these are bundled on every desktop platform rather
than just where convenient. End users never need to install anything
themselves; see `FfmpegLocator.resolve()` for how the bundled copy is found
at runtime (`<bundle>/tools/ffmpeg[.exe]` next to the app's own executable).

**These are not Flutter assets.** They're installed into the bundle's
`tools/` directory by platform-specific build steps instead:

- Windows: `install(FILES ...)` at the bottom of `windows/CMakeLists.txt`,
  copying `ffmpeg.exe`/`ffprobe.exe` from this folder into
  `<bundle>/tools/`.
- macOS: a "Copy Bundled ffmpeg" Run Script build phase on the Runner target
  (see `macos/Runner.xcodeproj/project.pbxproj`), copying `ffmpeg`/`ffprobe`
  from this folder into `<App>.app/Contents/MacOS/tools/`, and
  `FFMPEG_LICENSE.txt` into `<App>.app/Contents/Resources/` instead - NOT
  alongside the binaries. codesign (even ad-hoc/unsigned) walks
  `Contents/MacOS/` expecting only executables, and fails the whole app's
  signature on finding a plain text file there.

Listing them under `flutter: assets:` in `pubspec.yaml` would ship them
inside every platform's bundle indiscriminately (Android, iOS, web too),
which is both wrong (they can't run there) and wasteful.

## Windows: ffmpeg.exe / ffprobe.exe

- Source: https://www.gyan.dev/ffmpeg/builds/ (the build linked from
  ffmpeg.org's own Windows download page), mirrored at
  https://github.com/GyanD/codexffmpeg/releases — `ffmpeg-8.1.2-essentials_build`.
- Version: 8.1.2. Pinned to this specific version (rather than the current
  `ffmpeg-release-essentials.zip`, which by 9.0.x has grown just over
  GitHub's 100 MB per-file limit) so both binaries can be committed directly
  without Git LFS. The 8.1.2 build is the same one already bundled by the
  `daw-project-manager` sibling project - `ffmpeg.exe` here is byte-for-byte
  identical to that repo's copy.
- License: GPLv3 — see `FFMPEG_LICENSE.txt` in this folder. Invoked as a
  separate subprocess (`Process.run`), never linked into the app binary.

To update: download a newer essentials build from the URL above (checking
that both `ffmpeg.exe` and `ffprobe.exe` individually stay under 100 MB, or
switch to Git LFS if a future version doesn't fit) and replace both files
(and `FFMPEG_LICENSE.txt` if it changed) — no code changes needed.

## macOS: ffmpeg / ffprobe

- Source: https://evermeet.cx/ffmpeg/ — static, universal (Apple
  Silicon + Intel) builds, linked from ffmpeg.org's own macOS download page.
- Version: 9.0.2.
- License: GPLv3 (same project, same license as the Windows build) — see
  `FFMPEG_LICENSE.txt`.
- These need their executable bit set (`chmod +x ffmpeg ffprobe`) - Windows
  has no such bit, so re-set it after replacing either file from a Windows
  checkout, and confirm `git ls-files -s` shows mode `100755` (not `100644`)
  before committing.

To update: download fresh `ffmpeg`/`ffprobe` zips from the URLs above,
extract, `chmod +x` both, and replace the files here.

## Verifying a bundle actually picked these up

`FfmpegLocator.resolve()` looks for `<bundle>/tools/ffmpeg[.exe]` and
`ffprobe[.exe]` next to the running executable before falling back to
`FFMPEG_PATH` or `PATH`. After a release build, check:

- Windows: `build\windows\x64\runner\Release\tools\ffmpeg.exe` exists.
- macOS: `build/macos/Build/Products/Release/Spinclip.app/Contents/MacOS/tools/ffmpeg`
  exists and is executable.
