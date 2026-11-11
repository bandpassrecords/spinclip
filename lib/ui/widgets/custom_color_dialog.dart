import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../util/color_hex.dart';

/// Shows a colour picker (saturation/brightness square, hue slider and hex
/// field) starting at [initial]. Returns the chosen colour, or null if the
/// user cancelled.
Future<Color?> showCustomColorDialog(BuildContext context, Color initial) {
  return showDialog<Color>(
    context: context,
    builder: (_) => _CustomColorDialog(initial: initial),
  );
}

class _CustomColorDialog extends StatefulWidget {
  final Color initial;

  const _CustomColorDialog({required this.initial});

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final _hexController = TextEditingController(
    text: _hexText(widget.initial),
  );

  static String _hexText(Color c) => hexFromColor(c).substring(2);

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  /// Updates the colour from the square/slider and mirrors it into the hex
  /// field.
  void _setHsv(HSVColor hsv) {
    setState(() => _hsv = hsv);
    _hexController.text = _hexText(hsv.toColor());
  }

  /// Updates the colour from the hex field once it holds a full RRGGBB value.
  void _onHexChanged(String text) {
    if (text.length != 6) return;
    final value = int.tryParse(text, radix: 16);
    if (value == null) return;
    setState(() => _hsv = HSVColor.fromColor(Color(0xFF000000 | value)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _hsv.toColor();
    return AlertDialog(
      title: Text(l10n.colorPickerTitle),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SaturationValueSquare(hsv: _hsv, onChanged: _setHsv),
            const SizedBox(height: 12),
            _HueSlider(hsv: _hsv, onChanged: _setHsv),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    decoration: const InputDecoration(
                      prefixText: '#',
                      labelText: 'Hex',
                      isDense: true,
                    ),
                    maxLength: 6,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                    ],
                    onChanged: _onHexChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(color),
          child: Text(l10n.colorPickerApply),
        ),
      ],
    );
  }
}

/// Saturation left-to-right, brightness top-to-bottom, for the current hue.
class _SaturationValueSquare extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  const _SaturationValueSquare({required this.hsv, required this.onChanged});

  void _handle(Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = 1 - (local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(s).withValue(v));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 180);
        return GestureDetector(
          onPanDown: (d) => _handle(d.localPosition, size),
          onPanUpdate: (d) => _handle(d.localPosition, size),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              size: size,
              painter: _SaturationValuePainter(hsv),
            ),
          ),
        );
      },
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  final HSVColor hsv;

  _SaturationValuePainter(this.hsv);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor()],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    final marker = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      marker,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black54,
    );
    canvas.drawCircle(
      marker,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter old) => old.hsv != hsv;
}

class _HueSlider extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  const _HueSlider({required this.hsv, required this.onChanged});

  void _handle(Offset local, double width) {
    onChanged(hsv.withHue((local.dx / width).clamp(0.0, 1.0) * 360));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onPanDown: (d) => _handle(d.localPosition, width),
          onPanUpdate: (d) => _handle(d.localPosition, width),
          child: CustomPaint(
            size: Size(width, 20),
            painter: _HuePainter(hsv.hue),
          ),
        );
      },
    );
  }
}

class _HuePainter extends CustomPainter {
  final double hue;

  _HuePainter(this.hue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var h = 0; h <= 360; h += 60)
              HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
          ],
        ).createShader(rect),
    );
    final x = hue / 360 * size.width;
    final thumb = Rect.fromCenter(
      center: Offset(x.clamp(3, size.width - 3), size.height / 2),
      width: 6,
      height: size.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(thumb, const Radius.circular(3)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(thumb, const Radius.circular(3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter old) => old.hue != hue;
}
