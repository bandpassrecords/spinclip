import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/visualizer_placement.dart';

class VisualizerPlacementPicker extends StatelessWidget {
  final VisualizerPlacement value;
  final ValueChanged<VisualizerPlacement> onChanged;

  const VisualizerPlacementPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<VisualizerPlacement>(
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.visualizerPlacementLabel),
      items: VisualizerPlacement.values
          .map((p) => DropdownMenuItem(value: p, child: Text(p.label(l10n))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
