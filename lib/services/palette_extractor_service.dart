import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Extracts a single accent color from a cover image, for the visualizer's
/// "Auto" color theme. Uses a saturation-weighted average rather than full
/// k-means clustering - simple and fast, and biased away from near-black/
/// near-white pixels so it picks up the image's actual hue instead of
/// washing out to gray on busy photos.
class PaletteExtractorService {
  static const fallbackHex = '0x33CCFF';

  Future<String> extractAccentColorHex(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return fallbackHex;

      final thumb = img.copyResize(
        decoded,
        width: 48,
        height: 48,
        maintainAspect: false,
      );

      double weightSum = 0;
      double rSum = 0, gSum = 0, bSum = 0;

      for (final pixel in thumb) {
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        final maxC = math.max(r, math.max(g, b));
        final minC = math.min(r, math.min(g, b));
        final lightness = (maxC + minC) / 2 / 255;
        if (lightness < 0.10 || lightness > 0.92) {
          continue; // skip near-black/near-white
        }

        final saturation = (maxC - minC) / 255;
        final weight = saturation * saturation; // favor vivid pixels strongly
        if (weight <= 0) continue;

        weightSum += weight;
        rSum += r * weight;
        gSum += g * weight;
        bSum += b * weight;
      }

      if (weightSum <= 0) return fallbackHex;

      final r = (rSum / weightSum).round().clamp(0, 255);
      final g = (gSum / weightSum).round().clamp(0, 255);
      final b = (bSum / weightSum).round().clamp(0, 255);
      return '0x${_hex2(r)}${_hex2(g)}${_hex2(b)}';
    } catch (_) {
      return fallbackHex;
    }
  }

  String _hex2(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
}
