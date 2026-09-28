import 'element_transform.dart';
import 'qr_caption_position.dart';
import 'track.dart';
import 'visualizer_placement.dart';
import 'visualizer_style.dart';

class RenderSettings {
  final String imagePath;
  final String audioPath;

  final VisualizerPlacement placement;
  final VisualizerStyle style;
  final String visualizerColorHex; // e.g. '0x33CCFF'
  final double blurRadius; // boxblur luma_radius

  /// 0.0 (choppy, default ffmpeg behavior) to 1.0 (very smooth). Maps to
  /// showfreqs' `averaging` (frame-count smoothing) for bar/line styles.
  final double visualizerSmoothness;

  final bool showCover;

  /// Fraction (0.1-1.0) of the shorter frame side the sharp cover is scaled
  /// to, so there's always a visible blurred border around it. Never
  /// upscales past the source image's own resolution regardless of this value.
  final double coverSizeFraction;
  final ElementTransform coverTransform;

  final bool showLogo;
  final String? logoImagePath;
  final ElementTransform logoTransform;

  final bool showText;
  final String textContent;
  final ElementTransform textTransform;

  final bool showQrCode;
  final String qrCodeContent;
  final String qrCaptionText;
  final QrCaptionPosition qrCaptionPosition;
  final ElementTransform qrTransform;

  /// Seconds of video+audio fade in/out at the start/end of the render. 0
  /// disables. Applied via ffmpeg's `fade`/`afade` filters.
  final double fadeInSeconds;
  final double fadeOutSeconds;

  /// When true (default), every render uses the full track and
  /// trimStart/trimDuration are ignored.
  final bool fullDuration;
  final double trimStartSeconds;
  final double? trimDurationSeconds;

  /// When true (default), audio is muxed uncompressed (PCM) instead of AAC,
  /// so no lossy audio generation is added on top of the source file. This
  /// requires a .mov container (MP4 doesn't support PCM audio reliably) -
  /// VideoRenderService picks the container extension based on this flag.
  /// Spotify Canvas overrides this to false regardless, since that platform
  /// strictly requires an MP4/AAC file.
  final bool losslessAudio;

  /// Mild "old school" aging look applied to the whole composited frame:
  /// warm sepia tint, slight desaturation/vignette, and light film grain.
  final bool vintageEffect;

  const RenderSettings({
    required this.imagePath,
    required this.audioPath,
    this.placement = VisualizerPlacement.bottomBand,
    this.style = VisualizerStyle.bars,
    this.visualizerColorHex = '0x33CCFF',
    this.blurRadius = 20,
    this.visualizerSmoothness = 0.5,
    this.showCover = true,
    this.coverSizeFraction = 0.82,
    this.coverTransform = ElementTransform.center,
    this.showLogo = false,
    this.logoImagePath,
    this.logoTransform = ElementTransform.bottomRight,
    this.showText = false,
    this.textContent = '',
    this.textTransform = ElementTransform.bottomCenter,
    this.showQrCode = false,
    this.qrCodeContent = '',
    this.qrCaptionText = '',
    this.qrCaptionPosition = QrCaptionPosition.below,
    this.qrTransform = ElementTransform.bottomLeft,
    this.fadeInSeconds = 0,
    this.fadeOutSeconds = 0,
    this.fullDuration = true,
    this.trimStartSeconds = 0,
    this.trimDurationSeconds,
    this.losslessAudio = true,
    this.vintageEffect = false,
  });

  RenderSettings copyWith({
    String? imagePath,
    String? audioPath,
    VisualizerPlacement? placement,
    VisualizerStyle? style,
    String? visualizerColorHex,
    double? blurRadius,
    double? visualizerSmoothness,
    bool? showCover,
    double? coverSizeFraction,
    ElementTransform? coverTransform,
    bool? showLogo,
    String? logoImagePath,
    ElementTransform? logoTransform,
    bool? showText,
    String? textContent,
    ElementTransform? textTransform,
    bool? showQrCode,
    String? qrCodeContent,
    String? qrCaptionText,
    QrCaptionPosition? qrCaptionPosition,
    ElementTransform? qrTransform,
    double? fadeInSeconds,
    double? fadeOutSeconds,
    bool? fullDuration,
    double? trimStartSeconds,
    double? trimDurationSeconds,
    bool? losslessAudio,
    bool? vintageEffect,
  }) {
    return RenderSettings(
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      placement: placement ?? this.placement,
      style: style ?? this.style,
      visualizerColorHex: visualizerColorHex ?? this.visualizerColorHex,
      blurRadius: blurRadius ?? this.blurRadius,
      visualizerSmoothness: visualizerSmoothness ?? this.visualizerSmoothness,
      showCover: showCover ?? this.showCover,
      coverSizeFraction: coverSizeFraction ?? this.coverSizeFraction,
      coverTransform: coverTransform ?? this.coverTransform,
      showLogo: showLogo ?? this.showLogo,
      logoImagePath: logoImagePath ?? this.logoImagePath,
      logoTransform: logoTransform ?? this.logoTransform,
      showText: showText ?? this.showText,
      textContent: textContent ?? this.textContent,
      textTransform: textTransform ?? this.textTransform,
      showQrCode: showQrCode ?? this.showQrCode,
      qrCodeContent: qrCodeContent ?? this.qrCodeContent,
      qrCaptionText: qrCaptionText ?? this.qrCaptionText,
      qrCaptionPosition: qrCaptionPosition ?? this.qrCaptionPosition,
      qrTransform: qrTransform ?? this.qrTransform,
      fadeInSeconds: fadeInSeconds ?? this.fadeInSeconds,
      fadeOutSeconds: fadeOutSeconds ?? this.fadeOutSeconds,
      fullDuration: fullDuration ?? this.fullDuration,
      trimStartSeconds: trimStartSeconds ?? this.trimStartSeconds,
      trimDurationSeconds: trimDurationSeconds ?? this.trimDurationSeconds,
      losslessAudio: losslessAudio ?? this.losslessAudio,
      vintageEffect: vintageEffect ?? this.vintageEffect,
    );
  }

  /// Builds the settings for one Track within a multi-song batch or medley,
  /// keeping this instance's shared template fields (placement, style,
  /// color, blur, logo, QR, fades, transforms) and swapping in the track's
  /// own image/audio/trim/title. Constructed directly (not via copyWith) so
  /// a track's explicit `null` trimDurationSeconds is preserved rather than
  /// falling back to this template's value.
  RenderSettings forTrack(Track track, {required String defaultImagePath}) {
    return RenderSettings(
      imagePath: track.imagePath ?? defaultImagePath,
      audioPath: track.audioPath,
      placement: placement,
      style: style,
      visualizerColorHex: visualizerColorHex,
      blurRadius: blurRadius,
      visualizerSmoothness: visualizerSmoothness,
      showCover: showCover,
      coverSizeFraction: coverSizeFraction,
      coverTransform: coverTransform,
      showLogo: showLogo,
      logoImagePath: logoImagePath,
      logoTransform: logoTransform,
      showText: showText,
      textContent: track.title ?? textContent,
      textTransform: textTransform,
      showQrCode: showQrCode,
      qrCodeContent: qrCodeContent,
      qrCaptionText: qrCaptionText,
      qrCaptionPosition: qrCaptionPosition,
      qrTransform: qrTransform,
      fadeInSeconds: fadeInSeconds,
      fadeOutSeconds: fadeOutSeconds,
      fullDuration: track.fullDuration,
      trimStartSeconds: track.trimStartSeconds,
      trimDurationSeconds: track.trimDurationSeconds,
      losslessAudio: losslessAudio,
      vintageEffect: vintageEffect,
    );
  }

  // Value equality so callers (e.g. the live preview panel) can tell whether
  // a freshly-built RenderSettings actually differs from the previous one,
  // rather than treating every rebuild as a change just because it's a new
  // instance.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RenderSettings &&
        other.imagePath == imagePath &&
        other.audioPath == audioPath &&
        other.placement == placement &&
        other.style == style &&
        other.visualizerColorHex == visualizerColorHex &&
        other.blurRadius == blurRadius &&
        other.visualizerSmoothness == visualizerSmoothness &&
        other.showCover == showCover &&
        other.coverSizeFraction == coverSizeFraction &&
        other.coverTransform == coverTransform &&
        other.showLogo == showLogo &&
        other.logoImagePath == logoImagePath &&
        other.logoTransform == logoTransform &&
        other.showText == showText &&
        other.textContent == textContent &&
        other.textTransform == textTransform &&
        other.showQrCode == showQrCode &&
        other.qrCodeContent == qrCodeContent &&
        other.qrCaptionText == qrCaptionText &&
        other.qrCaptionPosition == qrCaptionPosition &&
        other.qrTransform == qrTransform &&
        other.fadeInSeconds == fadeInSeconds &&
        other.fadeOutSeconds == fadeOutSeconds &&
        other.fullDuration == fullDuration &&
        other.trimStartSeconds == trimStartSeconds &&
        other.trimDurationSeconds == trimDurationSeconds &&
        other.losslessAudio == losslessAudio &&
        other.vintageEffect == vintageEffect;
  }

  @override
  int get hashCode => Object.hash(
        imagePath,
        audioPath,
        placement,
        style,
        visualizerColorHex,
        Object.hash(blurRadius, visualizerSmoothness, showCover, coverSizeFraction, coverTransform),
        Object.hash(showLogo, logoImagePath, logoTransform),
        Object.hash(showText, textContent, textTransform),
        Object.hash(showQrCode, qrCodeContent, qrCaptionText, qrCaptionPosition, qrTransform),
        Object.hash(fadeInSeconds, fadeOutSeconds),
        Object.hash(fullDuration, trimStartSeconds, trimDurationSeconds, losslessAudio, vintageEffect),
      );
}
