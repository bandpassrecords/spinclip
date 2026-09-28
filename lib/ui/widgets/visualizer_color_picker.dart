import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/palette_extractor_service.dart';
import '../../util/color_hex.dart';

/// Lets the user pick the visualizer's bar/wave color from a small preset
/// palette, or derive one automatically from the cover image ("Auto") or
/// from a couple of fixed mood presets ("Dark"/"Sparkling") - all of which
/// just set the same underlying hex color, so there's no separate "theme"
/// state to track beyond the color itself.
class VisualizerColorPicker extends StatefulWidget {
  final String colorHex; // e.g. '0x33CCFF'
  final ValueChanged<String> onColorChanged;
  final String? coverImagePath;

  const VisualizerColorPicker({
    super.key,
    required this.colorHex,
    required this.onColorChanged,
    required this.coverImagePath,
  });

  @override
  State<VisualizerColorPicker> createState() => _VisualizerColorPickerState();
}

class _VisualizerColorPickerState extends State<VisualizerColorPicker> {
  final _paletteExtractor = PaletteExtractorService();
  bool _extracting = false;

  static const _darkThemeHex = '0x6A0DAD';
  static const _sparklingThemeHex = '0xFFD700';

  static const _swatches = [
    '0x33CCFF',
    '0xFF3366',
    '0x33FF99',
    '0xFFCC33',
    '0xCC33FF',
    '0xFFFFFF',
    '0xFF6600',
    '0x00FFFF',
  ];

  Future<void> _applyAutoTheme() async {
    final path = widget.coverImagePath;
    if (path == null) return;
    setState(() => _extracting = true);
    final hex = await _paletteExtractor.extractAccentColorHex(path);
    if (!mounted) return;
    setState(() => _extracting = false);
    widget.onColorChanged(hex);
  }

  bool _isSelected(String hex) =>
      widget.colorHex.toUpperCase() == hex.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.visualizerColorLabel,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final hex in _swatches)
              _ColorSwatch(
                color: colorFromHex(hex),
                selected: _isSelected(hex),
                onTap: () => widget.onColorChanged(hex),
              ),
            ActionChip(
              avatar: _extracting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                _extracting ? l10n.extractingColor : l10n.colorThemeAuto,
              ),
              onPressed: widget.coverImagePath == null || _extracting
                  ? null
                  : _applyAutoTheme,
            ),
            ActionChip(
              avatar: const Icon(Icons.nightlight_round, size: 16),
              label: Text(l10n.colorThemeDark),
              onPressed: () => widget.onColorChanged(_darkThemeHex),
            ),
            ActionChip(
              avatar: const Icon(Icons.auto_fix_high, size: 16),
              label: Text(l10n.colorThemeSparkling),
              onPressed: () => widget.onColorChanged(_sparklingThemeHex),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.black26,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}
