import 'package:flutter/material.dart';

import '../../models/platform_preset.dart';

class PlatformPresetPicker extends StatelessWidget {
  final Set<String> selectedIds;
  final void Function(String presetId, bool selected) onToggle;

  const PlatformPresetPicker({super.key, required this.selectedIds, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlatformPreset.all.map((preset) {
        final selected = selectedIds.contains(preset.id);
        return FilterChip(
          label: Text('${preset.name} (${preset.aspectRatioLabel})'),
          selected: selected,
          onSelected: (v) => onToggle(preset.id, v),
        );
      }).toList(),
    );
  }
}
