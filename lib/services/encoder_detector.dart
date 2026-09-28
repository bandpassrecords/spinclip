import 'dart:io';

import 'ffmpeg_locator.dart';

/// Detects which hardware-accelerated H.264 encoder (if any) this machine's
/// ffmpeg build supports, by parsing `ffmpeg -encoders`. Falls back to the
/// software libx264 encoder when none is available or detection fails.
class EncoderDetector {
  final FfmpegLocator locator;
  EncoderDetector(this.locator);

  static const _hardwareEncodersInPriorityOrder = [
    'h264_nvenc', // NVIDIA
    'h264_qsv', // Intel Quick Sync
    'h264_amf', // AMD
    'h264_mf', // Windows Media Foundation (generic fallback GPU path)
    'h264_videotoolbox', // macOS
  ];

  String? _cachedHardwareEncoder;
  bool _detected = false;

  /// Returns the best available hardware encoder name, or null if only
  /// software encoding is available. Result is cached after the first probe.
  Future<String?> detectHardwareEncoder() async {
    if (_detected) return _cachedHardwareEncoder;
    _detected = true;

    try {
      final paths = await locator.resolve();
      final result = await Process.run(paths.ffmpeg, [
        '-hide_banner',
        '-encoders',
      ]);
      if (result.exitCode != 0) return null;
      final output = result.stdout.toString();

      for (final encoder in _hardwareEncodersInPriorityOrder) {
        if (output.contains(encoder)) {
          _cachedHardwareEncoder = encoder;
          return encoder;
        }
      }
    } catch (_) {
      // Fall through to software encoding if probing fails for any reason.
    }
    return null;
  }

  /// Resolves the codec to actually use, honoring the user's toggle and
  /// falling back to libx264 if hardware acceleration was requested but
  /// nothing usable was found.
  Future<String> resolveVideoCodec({required bool preferHardware}) async {
    if (!preferHardware) return 'libx264';
    return await detectHardwareEncoder() ?? 'libx264';
  }
}
