import 'package:flutter/material.dart';

/// Parses an ffmpeg-style '0xRRGGBB' hex string (the format used by
/// RenderSettings.visualizerColorHex) into a Flutter Color.
Color colorFromHex(String hex) {
  final clean = hex.replaceFirst('0x', '').padLeft(6, '0');
  return Color(int.parse('FF$clean', radix: 16));
}
