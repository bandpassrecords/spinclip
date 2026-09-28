import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/platform_preset.dart';
import '../../util/platform_brand_icon.dart';

class PlatformPresetPicker extends StatelessWidget {
  final Set<String> selectedIds;
  final void Function(String presetId, bool selected) onToggle;

  /// Advanced mode only: lets each selected preset's resolution be
  /// overridden below the chips.
  final bool showResolutionOverrides;
  final Map<String, (int, int)> resolutionOverrides;
  final void Function(String presetId, (int, int)? resolution)
  onResolutionChanged;

  const PlatformPresetPicker({
    super.key,
    required this.selectedIds,
    required this.onToggle,
    required this.showResolutionOverrides,
    required this.resolutionOverrides,
    required this.onResolutionChanged,
  });

  PlatformPreset _effective(PlatformPreset preset) {
    final override = resolutionOverrides[preset.id];
    return override == null
        ? preset
        : preset.copyWith(width: override.$1, height: override.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedPresets = PlatformPreset.all
        .where((preset) => selectedIds.contains(preset.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlatformPreset.all.map((preset) {
            final effective = _effective(preset);
            return FilterChip(
              avatar: platformBrandIcon(preset.id),
              label: Text('${preset.name} (${effective.aspectRatioLabel})'),
              selected: selectedIds.contains(preset.id),
              onSelected: (v) => onToggle(preset.id, v),
            );
          }).toList(),
        ),
        if (showResolutionOverrides && selectedPresets.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.customResolutionTitle,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          for (final preset in selectedPresets)
            _ResolutionOverrideRow(
              preset: preset,
              resolutionOverride: resolutionOverrides[preset.id],
              onChanged: (resolution) =>
                  onResolutionChanged(preset.id, resolution),
            ),
        ],
      ],
    );
  }
}

class _ResolutionOverrideRow extends StatelessWidget {
  final PlatformPreset preset;
  final (int, int)? resolutionOverride;
  final ValueChanged<(int, int)?> onChanged;

  const _ResolutionOverrideRow({
    required this.preset,
    required this.resolutionOverride,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = resolutionOverride?.$1 ?? preset.width;
    final height = resolutionOverride?.$2 ?? preset.height;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(preset.name, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: TextFormField(
              initialValue: width.toString(),
              decoration: InputDecoration(
                labelText: l10n.resolutionWidthLabel,
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) onChanged((parsed, height));
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('×'),
          ),
          Expanded(
            child: TextFormField(
              initialValue: height.toString(),
              decoration: InputDecoration(
                labelText: l10n.resolutionHeightLabel,
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) onChanged((width, parsed));
              },
            ),
          ),
          if (resolutionOverride != null)
            IconButton(
              icon: const Icon(Icons.restart_alt, size: 18),
              tooltip: l10n.resetResolutionTooltip,
              onPressed: () => onChanged(null),
            ),
        ],
      ),
    );
  }
}
