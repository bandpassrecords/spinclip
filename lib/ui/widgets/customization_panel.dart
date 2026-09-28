import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/qr_caption_position.dart';
import 'file_drop_target.dart';
import 'visualizer_color_picker.dart';

class CustomizationPanel extends StatelessWidget {
  final double blurRadius;
  final ValueChanged<double> onBlurChanged;
  final double visualizerSmoothness;
  final ValueChanged<double> onVisualizerSmoothnessChanged;
  final String visualizerColorHex;
  final ValueChanged<String> onVisualizerColorChanged;
  final String? coverImagePath;
  final bool vintageEffect;
  final ValueChanged<bool> onVintageEffectChanged;
  final bool showCover;
  final ValueChanged<bool> onShowCoverChanged;
  final double coverSizeFraction;
  final ValueChanged<double> onCoverSizeFractionChanged;
  final bool showLogo;
  final ValueChanged<bool> onShowLogoChanged;
  final String? logoImagePath;
  final ValueChanged<String> onLogoPathChanged;
  final bool showText;
  final ValueChanged<bool> onShowTextChanged;
  final String textContent;
  final ValueChanged<String> onTextContentChanged;
  final bool showQrCode;
  final ValueChanged<bool> onShowQrCodeChanged;
  final String qrCodeContent;
  final ValueChanged<String> onQrCodeContentChanged;
  final String qrCaptionText;
  final ValueChanged<String> onQrCaptionTextChanged;
  final QrCaptionPosition qrCaptionPosition;
  final ValueChanged<QrCaptionPosition> onQrCaptionPositionChanged;
  final double fadeInSeconds;
  final ValueChanged<double> onFadeInChanged;
  final double fadeOutSeconds;
  final ValueChanged<double> onFadeOutChanged;

  const CustomizationPanel({
    super.key,
    required this.blurRadius,
    required this.onBlurChanged,
    required this.visualizerSmoothness,
    required this.onVisualizerSmoothnessChanged,
    required this.visualizerColorHex,
    required this.onVisualizerColorChanged,
    required this.coverImagePath,
    required this.vintageEffect,
    required this.onVintageEffectChanged,
    required this.showCover,
    required this.onShowCoverChanged,
    required this.coverSizeFraction,
    required this.onCoverSizeFractionChanged,
    required this.showLogo,
    required this.onShowLogoChanged,
    required this.logoImagePath,
    required this.onLogoPathChanged,
    required this.showText,
    required this.onShowTextChanged,
    required this.textContent,
    required this.onTextContentChanged,
    required this.showQrCode,
    required this.onShowQrCodeChanged,
    required this.qrCodeContent,
    required this.onQrCodeContentChanged,
    required this.qrCaptionText,
    required this.onQrCaptionTextChanged,
    required this.qrCaptionPosition,
    required this.onQrCaptionPositionChanged,
    required this.fadeInSeconds,
    required this.onFadeInChanged,
    required this.fadeOutSeconds,
    required this.onFadeOutChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.backgroundBlurLabel(blurRadius.round())),
        Slider(
          value: blurRadius,
          min: 0,
          max: 40,
          divisions: 40,
          label: blurRadius.round().toString(),
          onChanged: onBlurChanged,
        ),
        Text(l10n.visualizerSmoothnessLabel((visualizerSmoothness * 100).round())),
        Slider(
          value: visualizerSmoothness,
          min: 0,
          max: 1,
          divisions: 20,
          label: '${(visualizerSmoothness * 100).round()}%',
          onChanged: onVisualizerSmoothnessChanged,
        ),
        const SizedBox(height: 8),
        VisualizerColorPicker(
          colorHex: visualizerColorHex,
          onColorChanged: onVisualizerColorChanged,
          coverImagePath: coverImagePath,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(l10n.vintageEffectLabel),
          subtitle: Text(l10n.vintageEffectSubtitle),
          value: vintageEffect,
          onChanged: onVintageEffectChanged,
        ),
        const Divider(height: 24),
        SwitchListTile(
          title: Text(l10n.showCoverArt),
          value: showCover,
          onChanged: onShowCoverChanged,
        ),
        if (showCover) ...[
          Text(l10n.coverSizeLabel((coverSizeFraction * 100).round())),
          Slider(
            value: coverSizeFraction,
            min: 0.2,
            max: 1.0,
            divisions: 32,
            label: '${(coverSizeFraction * 100).round()}%',
            onChanged: onCoverSizeFractionChanged,
          ),
        ],
        SwitchListTile(
          title: Text(l10n.showLogo),
          value: showLogo,
          onChanged: onShowLogoChanged,
        ),
        if (showLogo)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FileDropTarget(
              label: l10n.logoImage,
              selectedPath: logoImagePath,
              allowedExtensions: const ['png', 'jpg', 'jpeg'],
              onFileSelected: onLogoPathChanged,
            ),
          ),
        SwitchListTile(
          title: Text(l10n.showTextOverlay),
          value: showText,
          onChanged: onShowTextChanged,
        ),
        if (showText)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              decoration: InputDecoration(labelText: l10n.overlayText),
              controller: TextEditingController(text: textContent)
                ..selection = TextSelection.collapsed(offset: textContent.length),
              onChanged: onTextContentChanged,
            ),
          ),
        SwitchListTile(
          title: Text(l10n.showQrCode),
          subtitle: Text(l10n.qrCodeSubtitle),
          value: showQrCode,
          onChanged: onShowQrCodeChanged,
        ),
        if (showQrCode) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              decoration: InputDecoration(labelText: l10n.qrCodeContentLabel),
              controller: TextEditingController(text: qrCodeContent)
                ..selection = TextSelection.collapsed(offset: qrCodeContent.length),
              onChanged: onQrCodeContentChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              decoration: InputDecoration(labelText: l10n.qrCaptionLabel),
              controller: TextEditingController(text: qrCaptionText)
                ..selection = TextSelection.collapsed(offset: qrCaptionText.length),
              onChanged: onQrCaptionTextChanged,
            ),
          ),
          if (qrCaptionText.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<QrCaptionPosition>(
                segments: QrCaptionPosition.values
                    .map((v) => ButtonSegment(value: v, label: Text(v.label(l10n))))
                    .toList(),
                selected: {qrCaptionPosition},
                onSelectionChanged: (s) => onQrCaptionPositionChanged(s.first),
              ),
            ),
        ],
        const SizedBox(height: 8),
        Text(l10n.fadeInLabel(fadeInSeconds.toStringAsFixed(1))),
        Slider(
          value: fadeInSeconds,
          min: 0,
          max: 10,
          divisions: 20,
          label: '${fadeInSeconds.toStringAsFixed(1)}s',
          onChanged: onFadeInChanged,
        ),
        Text(l10n.fadeOutLabel(fadeOutSeconds.toStringAsFixed(1))),
        Slider(
          value: fadeOutSeconds,
          min: 0,
          max: 10,
          divisions: 20,
          label: '${fadeOutSeconds.toStringAsFixed(1)}s',
          onChanged: onFadeOutChanged,
        ),
      ],
    );
  }
}
