// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Spinclip';

  @override
  String get stepReleaseType => 'Release type';

  @override
  String get stepFiles => 'Files';

  @override
  String get stepVisualizer => 'Visualizer';

  @override
  String get stepCustomize => 'Customize';

  @override
  String get stepDuration => 'Duration';

  @override
  String get stepPlatforms => 'Platforms';

  @override
  String get stepOutputPerformance => 'Output & performance';

  @override
  String get stepReviewRender => 'Review & render';

  @override
  String stepIndicator(int current, int total, String stepName) {
    return 'Step $current of $total: $stepName';
  }

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get preview => 'Preview';

  @override
  String previewPresetLabel(String presetName, String aspectRatio) {
    return '$presetName ($aspectRatio)';
  }

  @override
  String get releaseModeSingle => 'Single song';

  @override
  String get releaseModeMultiSong => 'Multiple songs';

  @override
  String get releaseModeMedley => 'Medley';

  @override
  String get coverImageLabelSingle => 'Cover image (PNG/JPG)';

  @override
  String get coverImageLabelMulti =>
      'Default cover image (used unless a song overrides it)';

  @override
  String get audioFileLabel => 'Audio file (WAV/MP3/FLAC...)';

  @override
  String get medleyExplanation =>
      'Each song contributes a short excerpt; they play back to back as one combined video per platform.';

  @override
  String get multiSongExplanation =>
      'Each song renders its own independent output video, for every selected platform.';

  @override
  String get singleExplanation =>
      'One cover and one song produce a single video, for every selected platform.';

  @override
  String get positionAndRotate => 'Position & rotate';

  @override
  String get positionCanvasHint =>
      'Drag to position. Tap an element to adjust its rotation.';

  @override
  String rotationLabel(String label, int degrees) {
    return '$label rotation: $degrees°';
  }

  @override
  String get elementCover => 'Cover';

  @override
  String get elementLogo => 'Logo';

  @override
  String get elementText => 'Text';

  @override
  String get elementQrCode => 'QR code';

  @override
  String backgroundBlurLabel(int value) {
    return 'Background blur: $value';
  }

  @override
  String visualizerSmoothnessLabel(int percent) {
    return 'Visualizer smoothness: $percent%';
  }

  @override
  String get showCoverArt => 'Show cover art';

  @override
  String coverSizeLabel(int percent) {
    return 'Cover size: $percent%';
  }

  @override
  String get showLogo => 'Show logo';

  @override
  String get logoImage => 'Logo image';

  @override
  String get showTextOverlay => 'Show text overlay';

  @override
  String get overlayText => 'Overlay text';

  @override
  String get showQrCode => 'Show QR code';

  @override
  String get qrCodeSubtitle =>
      'Links to a URL of your choice (e.g. a Spotify/streaming link)';

  @override
  String get qrCodeContentLabel => 'QR code content (URL or text)';

  @override
  String get qrCaptionLabel => 'QR caption (optional, e.g. \"Scan to listen\")';

  @override
  String get qrCaptionPositionBelow => 'Below QR code';

  @override
  String get qrCaptionPositionAbove => 'Above QR code';

  @override
  String fadeInLabel(String seconds) {
    return 'Fade in: ${seconds}s';
  }

  @override
  String fadeOutLabel(String seconds) {
    return 'Fade out: ${seconds}s';
  }

  @override
  String dropFileHint(String label) {
    return '$label - click or drop a file here';
  }

  @override
  String get fullDuration => 'Full duration';

  @override
  String get fullDurationSubtitle =>
      'Use the entire track (default). Turn off to pick an excerpt.';

  @override
  String get probingTrackLength => 'Probing track length...';

  @override
  String trimRangeLabel(String start, String end, String duration) {
    return '$start - $end (${duration}s)';
  }

  @override
  String get previewExcerptButton => 'Preview the selected excerpt';

  @override
  String get addSong => 'Add song';

  @override
  String get trackStartSeconds => 'Start (s)';

  @override
  String get trackExcerptDuration => 'Excerpt duration (s)';

  @override
  String get outputDirectoryDefault =>
      'Default (Documents/Spinclip) - click to change';

  @override
  String get hardwareAcceleration => 'Hardware-accelerated encoding';

  @override
  String get hardwareAccelerationSubtitle =>
      'Uses your GPU (NVENC/Quick Sync/AMF) when available; falls back to software encoding automatically if it fails.';

  @override
  String get losslessAudio => 'Lossless audio (PCM)';

  @override
  String get losslessAudioSubtitle =>
      'No audio compression - writes a .mov file instead of .mp4. Spotify Canvas always uses AAC/MP4 regardless, since that platform requires it.';

  @override
  String get renderButton => 'Render';

  @override
  String get renderingPreview => 'Rendering preview...';

  @override
  String get renderingGeneric => 'Rendering...';

  @override
  String get selectCoverAndAudioFirst => 'Select a cover image and audio first';

  @override
  String renderProgressLabel(
    int index,
    int count,
    String presetName,
    String percent,
  ) {
    return '[$index/$count] $presetName: $percent%';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String renderDone(String path) {
    return 'Done! Saved to: $path';
  }

  @override
  String renderError(String message) {
    return 'Error: $message';
  }

  @override
  String get renderCancelled => 'Cancelled.';

  @override
  String get visualizerPlacementLabel => 'Visualizer placement';

  @override
  String get visualizerStyleLabel => 'Visualizer style';

  @override
  String get placementBottomBand => 'Bottom Band';

  @override
  String get placementSideBorder => 'Side Border';

  @override
  String get placementDualMirroredBottom => 'Dual Mirrored Bottom';

  @override
  String get placementFullFrameBorder => 'Full Frame Border';

  @override
  String get placementAscendingCorner => 'Ascending Corner';

  @override
  String get placementCenteredBehindText => 'Centered Behind Text';

  @override
  String get placementCoverCenterDualBars => 'Cover Center + Side Bars';

  @override
  String get styleBars => 'Bars';

  @override
  String get styleLineSpectrum => 'Line Spectrum';

  @override
  String get styleFluidWave => 'Fluid Wave';

  @override
  String get styleOscilloscope => 'Oscilloscope';

  @override
  String get reviewSummaryTitle => 'Summary';

  @override
  String get reviewEditTooltip => 'Edit';

  @override
  String get summaryValueNotSet => 'Not set';

  @override
  String summaryTrackCount(int count) {
    return '$count tracks';
  }

  @override
  String get summaryElementsNone => 'None';

  @override
  String get summaryOn => 'On';

  @override
  String get summaryOff => 'Off';

  @override
  String get summaryPlatformsNone => 'None selected';

  @override
  String get openOutputFolder => 'Open folder';

  @override
  String get resetPositions => 'Reset positions';

  @override
  String get visualizerColorLabel => 'Visualizer color';

  @override
  String get colorThemeAuto => 'Auto (from cover)';

  @override
  String get colorThemeDark => 'Dark';

  @override
  String get colorThemeSparkling => 'Sparkling';

  @override
  String get extractingColor => 'Extracting color...';

  @override
  String get vintageEffectLabel => 'Vintage look';

  @override
  String get vintageEffectSubtitle =>
      'Mild old-school aging: warm tone, soft vignette, light film grain.';

  @override
  String get filesStepRequiredHint =>
      'A cover image and audio are required to continue.';

  @override
  String get advancedModeLabel => 'Advanced settings';

  @override
  String get advancedModeSubtitle =>
      'Fine-tune the visualizer, overlays, timing, and export options. Off uses sensible defaults for all of it.';

  @override
  String get customResolutionTitle => 'Custom resolution';

  @override
  String get resolutionWidthLabel => 'Width';

  @override
  String get resolutionHeightLabel => 'Height';

  @override
  String get resetResolutionTooltip => 'Reset to default resolution';

  @override
  String get outputSubfolderLabel => 'Output subfolder name (optional)';

  @override
  String outputSubfolderHint(String name) {
    return 'Defaults to \"$name\", from the cover image';
  }

  @override
  String get overwriteConfirmTitle => 'Folder already has files';

  @override
  String overwriteConfirmMessage(String path) {
    return '\"$path\" already contains files from a previous render. Rendering again will overwrite them.';
  }

  @override
  String get overwriteConfirmButton => 'Overwrite';

  @override
  String get trackDefaultCoverHint => 'Uses the default cover';

  @override
  String get trackSetCover => 'Set cover';

  @override
  String get trackClearCoverTooltip => 'Remove custom cover';

  @override
  String get loadTemplateButton => 'Load template';

  @override
  String get saveAsTemplateButton => 'Save as template';

  @override
  String get templateNameLabel => 'Template name';

  @override
  String get noTemplatesSaved => 'No saved templates yet';

  @override
  String get deleteTemplateTooltip => 'Delete template';

  @override
  String get save => 'Save';
}
