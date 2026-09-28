import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/element_transform.dart';

class PositionableItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final ElementTransform transform;
  final bool enabled;
  final bool supportsRotation;

  const PositionableItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.transform,
    required this.enabled,
    this.supportsRotation = true,
  });
}

/// A schematic frame the user can drag elements around on (cover, logo, QR
/// code) to set their position, with a rotation slider for the selected
/// element. Positions are stored as fractions (0.0-1.0) of the frame, so
/// they carry over correctly across every aspect ratio/platform preset.
class PositionCanvas extends StatefulWidget {
  final int frameWidth;
  final int frameHeight;
  final List<PositionableItem> items;
  final void Function(String id, ElementTransform transform) onChanged;

  const PositionCanvas({
    super.key,
    required this.frameWidth,
    required this.frameHeight,
    required this.items,
    required this.onChanged,
  });

  @override
  State<PositionCanvas> createState() => _PositionCanvasState();
}

class _PositionCanvasState extends State<PositionCanvas> {
  String? _selectedId;

  static const _handleSize = 36.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabledItems = widget.items.where((i) => i.enabled).toList();
    final selected = enabledItems.where((i) => i.id == _selectedId).toList();
    final selectedItem = selected.isNotEmpty ? selected.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.positionCanvasHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: widget.frameWidth / widget.frameHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.maxWidth;
              final boxHeight = constraints.maxHeight;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final item in enabledItems)
                      Positioned(
                        left: item.transform.dx * boxWidth - _handleSize / 2,
                        top: item.transform.dy * boxHeight - _handleSize / 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedId = item.id),
                          onPanUpdate: (details) {
                            final newDx =
                                ((item.transform.dx * boxWidth) +
                                    details.delta.dx) /
                                boxWidth;
                            final newDy =
                                ((item.transform.dy * boxHeight) +
                                    details.delta.dy) /
                                boxHeight;
                            widget.onChanged(
                              item.id,
                              item.transform.copyWith(
                                dx: newDx.clamp(0.0, 1.0),
                                dy: newDy.clamp(0.0, 1.0),
                              ),
                            );
                            setState(() => _selectedId = item.id);
                          },
                          child: Transform.rotate(
                            angle:
                                item.transform.rotationDegrees *
                                3.14159265358979 /
                                180.0,
                            child: Container(
                              width: _handleSize,
                              height: _handleSize,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: item.id == _selectedId
                                      ? Colors.white
                                      : Colors.black45,
                                  width: item.id == _selectedId ? 2.5 : 1,
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (selectedItem != null && selectedItem.supportsRotation) ...[
          const SizedBox(height: 8),
          Text(
            l10n.rotationLabel(
              selectedItem.label,
              selectedItem.transform.rotationDegrees.round(),
            ),
          ),
          Slider(
            value: selectedItem.transform.rotationDegrees,
            min: 0,
            max: 360,
            divisions: 72,
            label: '${selectedItem.transform.rotationDegrees.round()}°',
            onChanged: (v) => widget.onChanged(
              selectedItem.id,
              selectedItem.transform.copyWith(rotationDegrees: v),
            ),
          ),
        ],
      ],
    );
  }
}
