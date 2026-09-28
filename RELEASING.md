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
   - Builds an unsigned Windows zip, an unsigned macOS zip, and a Linux tarball, each with a
     `.sha256` checksum, and attaches them to the release.

Every pull request against `main` also runs the test suite and a Windows build check
(`test_pr_build`), independent of tagging.

## Not set up yet

No secrets are required today. Windows/Linux installer packaging (MSIX, Inno Setup, AppImage,
Flatpak), macOS code signing/notarization, and Windows code signing aren't wired up — today's
release artifacts are plain, unsigned zip/tarball bundles of the Flutter build output. macOS will
show an "unidentified developer" warning on first launch as a result. Revisit signing if/when this
ships to the App Store or otherwise needs a smoother first-run experience.
