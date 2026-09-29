# Releasing

Versioning follows semver (`X.Y.Z`), tracked in two places that must agree:
`pubspec.yaml`'s `version:` field and the newest `## vX.Y.Z` entry in `CHANGELOG.md`.
CI enforces this — a tag push fails immediately if `CHANGELOG.md` has no matching entry.

## Steps

1. Add a `## vX.Y.Z — YYYY-MM-DD` entry to the top of `CHANGELOG.md` describing what changed.
2. Run `./scripts/release.sh X.Y.Z` (add `--push` to push immediately, or push manually after
   reviewing the commit/tag it creates). This bumps `pubspec.yaml`, commits, and tags `vX.Y.Z`.
3. Before pushing the tag (or right after), create a GitHub Release for `vX.Y.Z` — the release
   workflow attaches build artifacts to an *existing* release, it does not create one.
4. Push the tag (if not already pushed with `--push`). `.github/workflows/release.yml` then:
   - Verifies `CHANGELOG.md` matches the tag and runs `flutter analyze` + `flutter test`.
   - Builds an unsigned Windows zip + unsigned Windows MSIX + unsigned Windows Inno Setup
     installer (`installer.iss` at repo root), an unsigned macOS zip, and a Linux tarball, each
     with a `.sha256` checksum, and attaches them to the release.

Every pull request against `main` also runs the test suite and a Windows build check
(`test_pr_build`), independent of tagging.

## ffmpeg is bundled, not a user prerequisite

Spinclip's entire rendering pipeline shells out to ffmpeg/ffprobe, so both are committed to the
repo under `resources/tools/` (see `resources/tools/README.md` for provenance/versions/how to
update) and bundled into every build automatically — `windows/CMakeLists.txt`'s `install(FILES
...)` for Windows, a "Copy Bundled ffmpeg" Run Script build phase on the macOS Runner target.
`FfmpegLocator.resolve()` picks up the bundled copy first, falling back to `FFMPEG_PATH`/`PATH`
only if it's missing (e.g. running from source without a full `flutter build`). End users never
need to install ffmpeg themselves.

## Not set up yet

No secrets are required today. The Windows MSIX is unsigned (`store: true` in `msix_config` defers
signing to the Store rather than generating a local certificate) — installable via `Add-AppxPackage`
for sideload testing, but a real Store submission needs the BandPass Records Partner Center
`publisher` CN in `pubspec.yaml` double-checked first. Linux installer packaging (AppImage/Flatpak),
macOS code signing/notarization, and Windows code signing beyond the MSIX itself aren't wired up —
macOS will show an "unidentified developer" warning on first launch as a result. Revisit signing
if/when this ships to the App Store or otherwise needs a smoother first-run experience.
