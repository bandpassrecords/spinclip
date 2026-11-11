import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/visualizer_placement.dart';
import '../../models/visualizer_style.dart';

const _frameBackground = Color(0xFF1E1E2A);
const _coverColor = Color(0xFF5A5A6E);

/// A fixed, spectrum-like bar height (0-1) for bar [i] of [n]: loud lows
/// tapering toward the highs, with some ripple so it reads as audio.
double _barHeight(int i, int n) {
  final t = i / n;
  final ripple = 0.65 + 0.35 * math.pow(math.sin(i * 1.7 + 0.4), 2);
  return ((0.95 - 0.6 * t) * ripple).clamp(0.08, 1.0);
}

/// Draws [count] spectrum bars filling [rect], rising from its bottom edge, or
/// hanging from its top edge when [fromTop] is set.
void _drawBars(
  Canvas canvas,
  Rect rect,
  Paint paint, {
  int count = 14,
  bool fromTop = false,
  double gapFraction = 0.25,
}) {
  final slot = rect.width / count;
  for (var i = 0; i < count; i++) {
    final h = rect.height * _barHeight(i, count);
    final left = rect.left + i * slot;
    final right = left + slot * (1 - gapFraction);
    canvas.drawRect(
      fromTop
          ? Rect.fromLTRB(left, rect.top, right, rect.top + h)
          : Rect.fromLTRB(left, rect.bottom - h, right, rect.bottom),
      paint,
    );
  }
}

/// Mirror-image of [_drawBars] across the vertical axis, so the loud end sits
/// on the right (used for the right-hand side of symmetric placements).
void _drawBarsFlipped(Canvas canvas, Rect rect, Paint paint, {int count = 6}) {
  canvas.save();
  canvas.translate(rect.left + rect.right, 0);
  canvas.scale(-1, 1);
  _drawBars(canvas, rect, paint, count: count);
  canvas.restore();
}

/// Preview of where the visualizer sits in the frame, mirroring the
/// geometry used by FiltergraphBuilder for each placement.
class PlacementThumbnailPainter extends CustomPainter {
  final VisualizerPlacement placement;
  final Color color;

  PlacementThumbnailPainter({required this.placement, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = _frameBackground);

    final coverSide = h * 0.6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, h / 2),
          width: coverSide,
          height: coverSide,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = _coverColor,
    );

    final bar = Paint()..color = color;
    switch (placement) {
      case VisualizerPlacement.bottomBand:
        _drawBars(canvas, Rect.fromLTRB(0, h * 0.78, w, h), bar, count: 20);
      case VisualizerPlacement.sideBorder:
        _drawBars(canvas, Rect.fromLTRB(0, 0, w * 0.12, h), bar, count: 4);
      case VisualizerPlacement.dualMirroredBottom:
        final mid = h * 0.89;
        _drawBars(canvas, Rect.fromLTRB(0, h * 0.78, w, mid), bar, count: 20);
        _drawBars(
          canvas,
          Rect.fromLTRB(0, mid, w, h),
          bar,
          count: 20,
          fromTop: true,
        );
      case VisualizerPlacement.fullFrameBorder:
        _drawBars(canvas, Rect.fromLTRB(0, h * 0.88, w, h), bar, count: 20);
        _drawBars(
          canvas,
          Rect.fromLTRB(0, 0, w, h * 0.12),
          bar,
          count: 20,
          fromTop: true,
        );
      case VisualizerPlacement.ascendingCorner:
        _drawBars(
          canvas,
          Rect.fromLTRB(0, h * 0.75, w * 0.4, h),
          bar,
          count: 8,
        );
      case VisualizerPlacement.centeredBehindText:
        _drawBars(
          canvas,
          Rect.fromCenter(
            center: Offset(w / 2, h / 2),
            width: w * 0.55,
            height: h * 0.3,
          ),
          bar,
          count: 12,
        );
        // Stand-in for the overlaid title text.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(w / 2, h / 2),
              width: w * 0.3,
              height: h * 0.07,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white70,
        );
      case VisualizerPlacement.coverCenterDualBars:
        _drawBars(canvas, Rect.fromLTRB(0, 0, w * 0.12, h), bar, count: 4);
        _drawBarsFlipped(
          canvas,
          Rect.fromLTRB(w * 0.88, 0, w, h),
          bar,
          count: 4,
        );
    }
  }

  @override
  bool shouldRepaint(covariant PlacementThumbnailPainter old) =>
      old.placement != placement || old.color != color;
}

/// Preview of what each visualizer style looks like.
class StyleThumbnailPainter extends CustomPainter {
  final VisualizerStyle style;
  final Color color;

  StyleThumbnailPainter({required this.style, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = _frameBackground);
    final area = Rect.fromLTRB(w * 0.06, h * 0.15, w * 0.94, h * 0.9);
    final fill = Paint()..color = color;

    switch (style) {
      case VisualizerStyle.bars:
        _drawBars(canvas, area, fill, count: 28, gapFraction: 0.1);
      case VisualizerStyle.lineSpectrum:
        const n = 28;
        final path = Path();
        for (var i = 0; i <= n; i++) {
          final x = area.left + area.width * i / n;
          final y = area.bottom - area.height * _barHeight(i, n);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeJoin = StrokeJoin.round,
        );
      case VisualizerStyle.fluidWave:
        // showwaves "cline": vertical lines centred on the midline.
        const n = 48;
        final midY = area.center.dy;
        final line = Paint()
          ..color = color
          ..strokeWidth = 1.2;
        for (var i = 0; i < n; i++) {
          final x = area.left + area.width * i / n;
          final amp =
              area.height /
              2 *
              (0.25 + 0.7 * math.sin(i * 0.33).abs() * _barHeight(i, n));
          canvas.drawLine(Offset(x, midY - amp), Offset(x, midY + amp), line);
        }
      case VisualizerStyle.oscilloscope:
        final center = Offset(w / 2, h / 2);
        final r = h * 0.38;
        final path = Path();
        for (var i = 0; i <= 200; i++) {
          final t = i / 200 * 2 * math.pi;
          final p = center.translate(
            r * math.sin(3 * t + 0.5),
            r * 0.9 * math.sin(2 * t),
          );
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      case VisualizerStyle.neonGlow:
        _drawBars(
          canvas,
          area,
          Paint()
            ..color = color.withValues(alpha: 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          count: 28,
          gapFraction: 0.1,
        );
        _drawBars(canvas, area, fill, count: 28, gapFraction: 0.1);
      case VisualizerStyle.cartoon:
        final outline = Paint()
          ..color = Color.lerp(color, Colors.black, 0.7)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        const n = 9;
        final slot = area.width / n;
        for (var i = 0; i < n; i++) {
          final bh = area.height * _barHeight(i, n);
          final rect = Rect.fromLTRB(
            area.left + i * slot + 1,
            area.bottom - bh,
            area.left + (i + 1) * slot - slot * 0.2,
            area.bottom,
          );
          canvas.drawRect(rect, fill);
          canvas.drawRect(rect, outline);
        }
    }
  }

  @override
  bool shouldRepaint(covariant StyleThumbnailPainter old) =>
      old.style != style || old.color != color;
}
