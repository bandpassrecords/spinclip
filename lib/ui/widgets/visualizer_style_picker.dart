import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/visualizer_style.dart';
import 'visual_option_picker.dart';
import 'visualizer_thumbnails.dart';

class VisualizerStylePicker extends StatelessWidget {
  final VisualizerStyle value;
  final ValueChanged<VisualizerStyle> onChanged;

  /// The visualizer colour, so the previews show the user's choice.
  final Color color;

  const VisualizerStylePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return VisualOptionPicker<VisualizerStyle>(
      label: l10n.visualizerStyleLabel,
      options: VisualizerStyle.values,
      value: value,
      onChanged: onChanged,
      optionLabel: (s) => s.label(l10n),
      previewPainter: (s) => StyleThumbnailPainter(style: s, color: color),
    );
  }
}
