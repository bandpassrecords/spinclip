import 'element_transform.dart';
import 'qr_caption_position.dart';
import 'release_mode.dart';
import 'visualizer_placement.dart';
import 'visualizer_style.dart';

/// A saved style configuration - everything about how a video looks and
/// behaves except the actual cover image(s) and song(s) - so the same look
/// can be reapplied to a different release later, or across a batch of many
/// releases sharing one style.
class RenderTemplate {
  final String name;

  final ReleaseMode releaseMode;
  final VisualizerPlacement placement;
  final VisualizerStyle style;
  final String visualizerColorHex;
  final double blurRadius;
  final double visualizerSmoothness;

  final bool showCover;
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

  final double fadeInSeconds;
  final double fadeOutSeconds;
  final bool fullDuration;

  final bool vintageEffect;
  final Set<String> selectedPresetIds;
  final bool useHardwareAcceleration;
  final bool losslessAudio;

  const RenderTemplate({
    required this.name,
    required this.releaseMode,
    required this.placement,
    required this.style,
    required this.visualizerColorHex,
    required this.blurRadius,
    required this.visualizerSmoothness,
    required this.showCover,
    required this.coverSizeFraction,
    required this.coverTransform,
    required this.showLogo,
    required this.logoImagePath,
    required this.logoTransform,
    required this.showText,
    required this.textContent,
    required this.textTransform,
    required this.showQrCode,
    required this.qrCodeContent,
    required this.qrCaptionText,
    required this.qrCaptionPosition,
    required this.qrTransform,
    required this.fadeInSeconds,
    required this.fadeOutSeconds,
    required this.fullDuration,
    required this.vintageEffect,
    required this.selectedPresetIds,
    required this.useHardwareAcceleration,
    required this.losslessAudio,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'releaseMode': releaseMode.name,
    'placement': placement.name,
    'style': style.name,
    'visualizerColorHex': visualizerColorHex,
    'blurRadius': blurRadius,
    'visualizerSmoothness': visualizerSmoothness,
    'showCover': showCover,
    'coverSizeFraction': coverSizeFraction,
    'coverTransform': _transformToJson(coverTransform),
    'showLogo': showLogo,
    'logoImagePath': logoImagePath,
    'logoTransform': _transformToJson(logoTransform),
    'showText': showText,
    'textContent': textContent,
    'textTransform': _transformToJson(textTransform),
    'showQrCode': showQrCode,
    'qrCodeContent': qrCodeContent,
    'qrCaptionText': qrCaptionText,
    'qrCaptionPosition': qrCaptionPosition.name,
    'qrTransform': _transformToJson(qrTransform),
    'fadeInSeconds': fadeInSeconds,
    'fadeOutSeconds': fadeOutSeconds,
    'fullDuration': fullDuration,
    'vintageEffect': vintageEffect,
    'selectedPresetIds': selectedPresetIds.toList(),
    'useHardwareAcceleration': useHardwareAcceleration,
    'losslessAudio': losslessAudio,
  };

  static Map<String, double> _transformToJson(ElementTransform t) => {
    'dx': t.dx,
    'dy': t.dy,
    'rotationDegrees': t.rotationDegrees,
  };

  static ElementTransform _transformFromJson(
    Object? json,
    ElementTransform fallback,
  ) {
    if (json is! Map) return fallback;
    return ElementTransform(
      dx: (json['dx'] as num?)?.toDouble() ?? fallback.dx,
      dy: (json['dy'] as num?)?.toDouble() ?? fallback.dy,
      rotationDegrees:
          (json['rotationDegrees'] as num?)?.toDouble() ??
          fallback.rotationDegrees,
    );
  }

  factory RenderTemplate.fromJson(Map<String, dynamic> json) {
    return RenderTemplate(
      name: json['name'] as String,
      releaseMode: ReleaseMode.values.byName(
        json['releaseMode'] as String? ?? ReleaseMode.single.name,
      ),
      placement: VisualizerPlacement.values.byName(
        json['placement'] as String? ?? VisualizerPlacement.bottomBand.name,
      ),
      style: VisualizerStyle.values.byName(
        json['style'] as String? ?? VisualizerStyle.bars.name,
      ),
      visualizerColorHex: json['visualizerColorHex'] as String? ?? '0x33CCFF',
      blurRadius: (json['blurRadius'] as num?)?.toDouble() ?? 20,
      visualizerSmoothness:
          (json['visualizerSmoothness'] as num?)?.toDouble() ?? 0.5,
      showCover: json['showCover'] as bool? ?? true,
      coverSizeFraction:
          (json['coverSizeFraction'] as num?)?.toDouble() ?? 0.82,
      coverTransform: _transformFromJson(
        json['coverTransform'],
        ElementTransform.center,
      ),
      showLogo: json['showLogo'] as bool? ?? false,
      logoImagePath: json['logoImagePath'] as String?,
      logoTransform: _transformFromJson(
        json['logoTransform'],
        ElementTransform.bottomRight,
      ),
      showText: json['showText'] as bool? ?? false,
      textContent: json['textContent'] as String? ?? '',
      textTransform: _transformFromJson(
        json['textTransform'],
        ElementTransform.bottomCenter,
      ),
      showQrCode: json['showQrCode'] as bool? ?? false,
      qrCodeContent: json['qrCodeContent'] as String? ?? '',
      qrCaptionText: json['qrCaptionText'] as String? ?? '',
      qrCaptionPosition: QrCaptionPosition.values.byName(
        json['qrCaptionPosition'] as String? ?? QrCaptionPosition.below.name,
      ),
      qrTransform: _transformFromJson(
        json['qrTransform'],
        ElementTransform.bottomLeft,
      ),
      fadeInSeconds: (json['fadeInSeconds'] as num?)?.toDouble() ?? 0,
      fadeOutSeconds: (json['fadeOutSeconds'] as num?)?.toDouble() ?? 0,
      fullDuration: json['fullDuration'] as bool? ?? true,
      vintageEffect: json['vintageEffect'] as bool? ?? false,
      selectedPresetIds:
          ((json['selectedPresetIds'] as List?)?.cast<String>() ??
                  const ['youtube'])
              .toSet(),
      useHardwareAcceleration: json['useHardwareAcceleration'] as bool? ?? true,
      losslessAudio: json['losslessAudio'] as bool? ?? true,
    );
  }
}
