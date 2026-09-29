import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/visualizer_placement.dart';
import 'visual_option_picker.dart';
import 'visualizer_thumbnails.dart';

class VisualizerPlacementPicker extends StatelessWidget {
  final VisualizerPlacement value;
  final ValueChanged<VisualizerPlacement> onChanged;

  /// The visualizer colour, so the previews show the user's choice.
  final Color color;

  const VisualizerPlacementPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return VisualOptionPicker<VisualizerPlacement>(
      label: l10n.visualizerPlacementLabel,
      options: VisualizerPlacement.values,
      value: value,
      onChanged: onChanged,
      optionLabel: (p) => p.label(l10n),
      previewPainter: (p) =>
          PlacementThumbnailPainter(placement: p, color: color),
    );
  }
}
