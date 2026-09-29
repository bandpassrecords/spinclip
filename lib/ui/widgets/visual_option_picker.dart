import 'package:flutter/material.dart';

/// A labelled grid of selectable cards, each showing a small drawn preview of
/// the option, its name and a radio indicator. Used instead of a dropdown when
/// the options are easier to tell apart by picture than by name.
class VisualOptionPicker<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T option) optionLabel;
  final CustomPainter Function(T option) previewPainter;

  const VisualOptionPicker({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.optionLabel,
    required this.previewPainter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              _OptionCard(
                label: optionLabel(option),
                painter: previewPainter(option),
                selected: option == value,
                onTap: () => onChanged(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final CustomPainter painter;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.painter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 136,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CustomPaint(painter: painter),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
