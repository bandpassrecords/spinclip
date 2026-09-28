import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/visualizer_style.dart';

class VisualizerStylePicker extends StatelessWidget {
  final VisualizerStyle value;
  final ValueChanged<VisualizerStyle> onChanged;

  const VisualizerStylePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<VisualizerStyle>(
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.visualizerStyleLabel),
      items: VisualizerStyle.values
          .map((s) => DropdownMenuItem(value: s, child: Text(s.label(l10n))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
