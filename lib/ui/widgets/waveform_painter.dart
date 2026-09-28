import 'package:flutter/material.dart';

/// Draws a peak-envelope waveform, dimming everything outside
/// [selectionStartFraction, selectionEndFraction] (the chosen excerpt) and
/// drawing a playhead line at [playheadFraction] when set.
class WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double selectionStartFraction;
  final double selectionEndFraction;
  final double? playheadFraction;
  final Color barColor;
  final Color dimmedBarColor;
  final Color selectionOverlayColor;
  final Color playheadColor;

  WaveformPainter({
    required this.peaks,
    required this.selectionStartFraction,
    required this.selectionEndFraction,
    this.playheadFraction,
    this.barColor = const Color(0xFF33CCFF),
    this.dimmedBarColor = const Color(0xFF4A4A4A),
    this.selectionOverlayColor = const Color(0x2233CCFF),
    this.playheadColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final barWidth = size.width / peaks.length;
    final midY = size.height / 2;

    for (var i = 0; i < peaks.length; i++) {
      final fraction = i / peaks.length;
      final inSelection =
          fraction >= selectionStartFraction &&
          fraction <= selectionEndFraction;
      final paint = Paint()..color = inSelection ? barColor : dimmedBarColor;
      final barHeight = (peaks[i] * size.height / 2).clamp(
        1.0,
        size.height / 2,
      );
      final x = i * barWidth;
      canvas.drawRect(
        Rect.fromLTRB(
          x,
          midY - barHeight,
          x + barWidth * 0.8,
          midY + barHeight,
        ),
        paint,
      );
    }

    if (selectionEndFraction > selectionStartFraction) {
      canvas.drawRect(
        Rect.fromLTRB(
          selectionStartFraction * size.width,
          0,
          selectionEndFraction * size.width,
          size.height,
        ),
        Paint()..color = selectionOverlayColor,
      );
    }

    final playhead = playheadFraction;
    if (playhead != null) {
      final x = playhead * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = playheadColor
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks ||
        oldDelegate.selectionStartFraction != selectionStartFraction ||
        oldDelegate.selectionEndFraction != selectionEndFraction ||
        oldDelegate.playheadFraction != playheadFraction;
  }
}
