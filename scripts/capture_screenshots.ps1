<#
.SYNOPSIS
  Retakes the website's screenshots and example videos from the real app.

.DESCRIPTION
  1. Makes the demo release (tool/demo_media/make_demo_media.dart): three
     abstract covers and three synthesized songs in build/demo_media/, so no
     picture ever shows someone else's artwork or music.
  2. Renders the example stills and clips through the real render pipeline
     (tool/demo_media/render_examples_test.dart) into resources/examples/.
  3. Drives the app in a desktop window through every wizard step
     (integration_test/screenshots/capture_test.dart) and writes
     resources/screenshots/<name>.png at 1920x1200.

  The website (website/) serves both folders itself. Not part of CI: run it
  when the UI or the look of a render changes.

.EXAMPLE
  scripts/capture_screenshots.ps1
#>
$repo = Split-Path -Parent $PSScriptRoot
Push-Location $repo
# The app and the tests find the repo's own ffmpeg, never one on PATH.
$env:FFMPEG_PATH = Join-Path $repo 'resources\tools'
try {
  dart run tool/demo_media/make_demo_media.dart
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  flutter test tool/demo_media/render_examples_test.dart
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  flutter test integration_test/screenshots/capture_test.dart -d windows
  $code = $LASTEXITCODE
} finally {
  Get-Process spinclip -ErrorAction SilentlyContinue | Stop-Process -Force
  Pop-Location
}
exit $code
