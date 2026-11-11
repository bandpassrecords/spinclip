import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Spinclip'**
  String get appTitle;

  /// No description provided for @stepReleaseType.
  ///
  /// In en, this message translates to:
  /// **'Release type'**
  String get stepReleaseType;

  /// No description provided for @stepFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get stepFiles;

  /// No description provided for @stepVisualizer.
  ///
  /// In en, this message translates to:
  /// **'Visualizer'**
  String get stepVisualizer;

  /// No description provided for @stepCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get stepCustomize;

  /// No description provided for @stepDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get stepDuration;

  /// No description provided for @stepPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get stepPlatforms;

  /// No description provided for @stepOutputPerformance.
  ///
  /// In en, this message translates to:
  /// **'Output & performance'**
  String get stepOutputPerformance;

  /// No description provided for @stepReviewRender.
  ///
  /// In en, this message translates to:
  /// **'Review & render'**
  String get stepReviewRender;

  /// No description provided for @stepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {stepName}'**
  String stepIndicator(int current, int total, String stepName);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previewPresetLabel.
  ///
  /// In en, this message translates to:
  /// **'{presetName} ({aspectRatio})'**
  String previewPresetLabel(String presetName, String aspectRatio);

  /// No description provided for @releaseModeSingle.
  ///
  /// In en, this message translates to:
  /// **'Single song'**
  String get releaseModeSingle;

  /// No description provided for @releaseModeMultiSong.
  ///
  /// In en, this message translates to:
  /// **'Multiple songs'**
  String get releaseModeMultiSong;

  /// No description provided for @releaseModeMedley.
  ///
  /// In en, this message translates to:
  /// **'Medley'**
  String get releaseModeMedley;

  /// No description provided for @coverImageLabelSingle.
  ///
  /// In en, this message translates to:
  /// **'Cover image (PNG/JPG)'**
  String get coverImageLabelSingle;

  /// No description provided for @coverImageLabelMulti.
  ///
  /// In en, this message translates to:
  /// **'Default cover image (used unless a song overrides it)'**
  String get coverImageLabelMulti;

  /// No description provided for @audioFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio file (WAV/MP3/FLAC...)'**
  String get audioFileLabel;

  /// No description provided for @medleyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Each song contributes a short excerpt; they play back to back as one combined video per platform.'**
  String get medleyExplanation;

  /// No description provided for @multiSongExplanation.
  ///
  /// In en, this message translates to:
  /// **'Each song renders its own independent output video, for every selected platform.'**
  String get multiSongExplanation;

  /// No description provided for @singleExplanation.
  ///
  /// In en, this message translates to:
  /// **'One cover and one song produce a single video, for every selected platform.'**
  String get singleExplanation;

  /// No description provided for @positionAndRotate.
  ///
  /// In en, this message translates to:
  /// **'Position & rotate'**
  String get positionAndRotate;

  /// No description provided for @positionCanvasHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to position. Tap an element to adjust its rotation.'**
  String get positionCanvasHint;

  /// No description provided for @rotationLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} rotation: {degrees}°'**
  String rotationLabel(String label, int degrees);

  /// No description provided for @elementCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get elementCover;

  /// No description provided for @elementLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get elementLogo;

  /// No description provided for @elementText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get elementText;

  /// No description provided for @elementQrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get elementQrCode;

  /// No description provided for @backgroundBlurLabel.
  ///
  /// In en, this message translates to:
  /// **'Background blur: {value}'**
  String backgroundBlurLabel(int value);

  /// No description provided for @visualizerSmoothnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Visualizer smoothness: {percent}%'**
  String visualizerSmoothnessLabel(int percent);

  /// No description provided for @visualizerSensitivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Visualizer sensitivity: {value}x'**
  String visualizerSensitivityLabel(String value);

  /// No description provided for @visualizerBarCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of bars: {count}'**
  String visualizerBarCountLabel(int count);

  /// No description provided for @visualizerBarCountAuto.
  ///
  /// In en, this message translates to:
  /// **'Number of bars: Auto'**
  String get visualizerBarCountAuto;

  /// No description provided for @visualizerBarCountAutoShort.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get visualizerBarCountAutoShort;

  /// No description provided for @showCoverArt.
  ///
  /// In en, this message translates to:
  /// **'Show cover art'**
  String get showCoverArt;

  /// No description provided for @coverSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover size: {percent}%'**
  String coverSizeLabel(int percent);

  /// No description provided for @showLogo.
  ///
  /// In en, this message translates to:
  /// **'Show logo'**
  String get showLogo;

  /// No description provided for @logoImage.
  ///
  /// In en, this message translates to:
  /// **'Logo image'**
  String get logoImage;

  /// No description provided for @showTextOverlay.
  ///
  /// In en, this message translates to:
  /// **'Show text overlay'**
  String get showTextOverlay;

  /// No description provided for @overlayText.
  ///
  /// In en, this message translates to:
  /// **'Overlay text'**
  String get overlayText;

  /// No description provided for @showQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get showQrCode;

  /// No description provided for @qrCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Links to a URL of your choice (e.g. a Spotify/streaming link)'**
  String get qrCodeSubtitle;

  /// No description provided for @qrCodeContentLabel.
  ///
  /// In en, this message translates to:
  /// **'QR code content (URL or text)'**
  String get qrCodeContentLabel;

  /// No description provided for @qrCaptionLabel.
  ///
  /// In en, this message translates to:
  /// **'QR caption (optional, e.g. \"Scan to listen\")'**
  String get qrCaptionLabel;

  /// No description provided for @qrCaptionPositionBelow.
  ///
  /// In en, this message translates to:
  /// **'Below QR code'**
  String get qrCaptionPositionBelow;

  /// No description provided for @qrCaptionPositionAbove.
  ///
  /// In en, this message translates to:
  /// **'Above QR code'**
  String get qrCaptionPositionAbove;

  /// No description provided for @fadeInLabel.
  ///
  /// In en, this message translates to:
  /// **'Fade in: {seconds}s'**
  String fadeInLabel(String seconds);

  /// No description provided for @fadeOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Fade out: {seconds}s'**
  String fadeOutLabel(String seconds);

  /// No description provided for @dropFileHint.
  ///
  /// In en, this message translates to:
  /// **'{label} - click or drop a file here'**
  String dropFileHint(String label);

  /// No description provided for @fullDuration.
  ///
  /// In en, this message translates to:
  /// **'Full duration'**
  String get fullDuration;

  /// No description provided for @fullDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the entire track (default). Turn off to pick an excerpt.'**
  String get fullDurationSubtitle;

  /// No description provided for @probingTrackLength.
  ///
  /// In en, this message translates to:
  /// **'Probing track length...'**
  String get probingTrackLength;

  /// No description provided for @trimRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end} ({duration}s)'**
  String trimRangeLabel(String start, String end, String duration);

  /// No description provided for @previewExcerptButton.
  ///
  /// In en, this message translates to:
  /// **'Preview the selected excerpt'**
  String get previewExcerptButton;

  /// No description provided for @songInfoLoading.
  ///
  /// In en, this message translates to:
  /// **'Reading song details...'**
  String get songInfoLoading;

  /// No description provided for @songInfoError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this file. Check that it\'s a supported audio file.'**
  String get songInfoError;

  /// No description provided for @playSongButton.
  ///
  /// In en, this message translates to:
  /// **'Play song'**
  String get playSongButton;

  /// No description provided for @channelsMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get channelsMono;

  /// No description provided for @channelsStereo.
  ///
  /// In en, this message translates to:
  /// **'Stereo'**
  String get channelsStereo;

  /// No description provided for @channelsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} channels'**
  String channelsCount(int count);

  /// No description provided for @audioLossless.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get audioLossless;

  /// No description provided for @audioLossy.
  ///
  /// In en, this message translates to:
  /// **'Lossy'**
  String get audioLossy;

  /// No description provided for @addSong.
  ///
  /// In en, this message translates to:
  /// **'Add song'**
  String get addSong;

  /// No description provided for @trackStartSeconds.
  ///
  /// In en, this message translates to:
  /// **'Start (s)'**
  String get trackStartSeconds;

  /// No description provided for @trackExcerptDuration.
  ///
  /// In en, this message translates to:
  /// **'Excerpt duration (s)'**
  String get trackExcerptDuration;

  /// No description provided for @outputDirectoryDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (Documents/Spinclip) - click to change'**
  String get outputDirectoryDefault;

  /// No description provided for @hardwareAcceleration.
  ///
  /// In en, this message translates to:
  /// **'Hardware-accelerated encoding'**
  String get hardwareAcceleration;

  /// No description provided for @hardwareAccelerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses your GPU (NVENC/Quick Sync/AMF) when available; falls back to software encoding automatically if it fails.'**
  String get hardwareAccelerationSubtitle;

  /// No description provided for @losslessAudio.
  ///
  /// In en, this message translates to:
  /// **'Lossless audio (PCM)'**
  String get losslessAudio;

  /// No description provided for @losslessAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No audio compression - writes a .mov file instead of .mp4. Spotify Canvas always uses AAC/MP4 regardless, since that platform requires it.'**
  String get losslessAudioSubtitle;

  /// No description provided for @renderButton.
  ///
  /// In en, this message translates to:
  /// **'Render'**
  String get renderButton;

  /// No description provided for @renderingPreview.
  ///
  /// In en, this message translates to:
  /// **'Rendering preview...'**
  String get renderingPreview;

  /// No description provided for @renderingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Rendering...'**
  String get renderingGeneric;

  /// No description provided for @selectCoverAndAudioFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a cover image and audio first'**
  String get selectCoverAndAudioFirst;

  /// No description provided for @renderProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'[{index}/{count}] {presetName}: {percent}%'**
  String renderProgressLabel(
    int index,
    int count,
    String presetName,
    String percent,
  );

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @renderDone.
  ///
  /// In en, this message translates to:
  /// **'Done! Saved to: {path}'**
  String renderDone(String path);

  /// No description provided for @renderError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String renderError(String message);

  /// No description provided for @renderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get renderCancelled;

  /// No description provided for @visualizerPlacementLabel.
  ///
  /// In en, this message translates to:
  /// **'Visualizer placement'**
  String get visualizerPlacementLabel;

  /// No description provided for @visualizerStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Visualizer style'**
  String get visualizerStyleLabel;

  /// No description provided for @placementBottomBand.
  ///
  /// In en, this message translates to:
  /// **'Bottom Band'**
  String get placementBottomBand;

  /// No description provided for @placementSideBorder.
  ///
  /// In en, this message translates to:
  /// **'Side Border'**
  String get placementSideBorder;

  /// No description provided for @placementDualMirroredBottom.
  ///
  /// In en, this message translates to:
  /// **'Dual Mirrored Bottom'**
  String get placementDualMirroredBottom;

  /// No description provided for @placementFullFrameBorder.
  ///
  /// In en, this message translates to:
  /// **'Full Frame Border'**
  String get placementFullFrameBorder;

  /// No description provided for @placementAscendingCorner.
  ///
  /// In en, this message translates to:
  /// **'Ascending Corner'**
  String get placementAscendingCorner;

  /// No description provided for @placementCenteredBehindText.
  ///
  /// In en, this message translates to:
  /// **'Centered Behind Text'**
  String get placementCenteredBehindText;

  /// No description provided for @placementCoverCenterDualBars.
  ///
  /// In en, this message translates to:
  /// **'Cover Center + Side Bars'**
  String get placementCoverCenterDualBars;

  /// No description provided for @styleBars.
  ///
  /// In en, this message translates to:
  /// **'Bars'**
  String get styleBars;

  /// No description provided for @styleLineSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Line Spectrum'**
  String get styleLineSpectrum;

  /// No description provided for @styleFluidWave.
  ///
  /// In en, this message translates to:
  /// **'Fluid Wave'**
  String get styleFluidWave;

  /// No description provided for @styleOscilloscope.
  ///
  /// In en, this message translates to:
  /// **'Oscilloscope'**
  String get styleOscilloscope;

  /// No description provided for @styleNeonGlow.
  ///
  /// In en, this message translates to:
  /// **'Neon Glow'**
  String get styleNeonGlow;

  /// No description provided for @styleCartoon.
  ///
  /// In en, this message translates to:
  /// **'Cartoon'**
  String get styleCartoon;

  /// No description provided for @reviewSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reviewSummaryTitle;

  /// No description provided for @reviewEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get reviewEditTooltip;

  /// No description provided for @summaryValueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get summaryValueNotSet;

  /// No description provided for @summaryTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String summaryTrackCount(int count);

  /// No description provided for @summaryElementsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get summaryElementsNone;

  /// No description provided for @summaryOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get summaryOn;

  /// No description provided for @summaryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get summaryOff;

  /// No description provided for @summaryPlatformsNone.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get summaryPlatformsNone;

  /// No description provided for @openOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openOutputFolder;

  /// No description provided for @resetPositions.
  ///
  /// In en, this message translates to:
  /// **'Reset positions'**
  String get resetPositions;

  /// No description provided for @visualizerColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Visualizer color'**
  String get visualizerColorLabel;

  /// No description provided for @colorThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (from cover)'**
  String get colorThemeAuto;

  /// No description provided for @colorThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get colorThemeDark;

  /// No description provided for @colorThemeSparkling.
  ///
  /// In en, this message translates to:
  /// **'Sparkling'**
  String get colorThemeSparkling;

  /// No description provided for @extractingColor.
  ///
  /// In en, this message translates to:
  /// **'Extracting color...'**
  String get extractingColor;

  /// No description provided for @colorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get colorCustom;

  /// No description provided for @colorPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get colorPickerTitle;

  /// No description provided for @colorPickerApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get colorPickerApply;

  /// No description provided for @visualizerGradientLabel.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get visualizerGradientLabel;

  /// No description provided for @visualizerGradientHint.
  ///
  /// In en, this message translates to:
  /// **'Blend from the edge into a second color at the bar tips'**
  String get visualizerGradientHint;

  /// No description provided for @visualizerGradientColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip color'**
  String get visualizerGradientColorLabel;

  /// No description provided for @vintageEffectLabel.
  ///
  /// In en, this message translates to:
  /// **'Vintage look'**
  String get vintageEffectLabel;

  /// No description provided for @vintageEffectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mild old-school aging: warm tone, soft vignette, light film grain.'**
  String get vintageEffectSubtitle;

  /// No description provided for @filesStepRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'A cover image and audio are required to continue.'**
  String get filesStepRequiredHint;

  /// No description provided for @advancedModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get advancedModeLabel;

  /// No description provided for @advancedModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune the visualizer, overlays, timing, and export options. Off uses sensible defaults for all of it.'**
  String get advancedModeSubtitle;

  /// No description provided for @customResolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom resolution'**
  String get customResolutionTitle;

  /// No description provided for @resolutionWidthLabel.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get resolutionWidthLabel;

  /// No description provided for @resolutionHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get resolutionHeightLabel;

  /// No description provided for @resetResolutionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset to default resolution'**
  String get resetResolutionTooltip;

  /// No description provided for @outputSubfolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Output subfolder name (optional)'**
  String get outputSubfolderLabel;

  /// No description provided for @outputSubfolderHint.
  ///
  /// In en, this message translates to:
  /// **'Defaults to \"{name}\", from the cover image'**
  String outputSubfolderHint(String name);

  /// No description provided for @overwriteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder already has files'**
  String get overwriteConfirmTitle;

  /// No description provided for @overwriteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{path}\" already contains files from a previous render. Rendering again will overwrite them.'**
  String overwriteConfirmMessage(String path);

  /// No description provided for @overwriteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwriteConfirmButton;

  /// No description provided for @trackDefaultCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Uses the default cover'**
  String get trackDefaultCoverHint;

  /// No description provided for @trackSetCover.
  ///
  /// In en, this message translates to:
  /// **'Set cover'**
  String get trackSetCover;

  /// No description provided for @trackClearCoverTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove custom cover'**
  String get trackClearCoverTooltip;

  /// No description provided for @loadTemplateButton.
  ///
  /// In en, this message translates to:
  /// **'Load template'**
  String get loadTemplateButton;

  /// No description provided for @builtInDefaultTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Spinclip default (Bars 48)'**
  String get builtInDefaultTemplateLabel;

  /// No description provided for @saveAsTemplateButton.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get saveAsTemplateButton;

  /// No description provided for @templateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateNameLabel;

  /// No description provided for @noTemplatesSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved templates yet'**
  String get noTemplatesSaved;

  /// No description provided for @deleteTemplateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get deleteTemplateTooltip;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
