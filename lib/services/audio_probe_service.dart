import 'dart:convert';
import 'dart:io';

import '../models/audio_info.dart';
import 'ffmpeg_locator.dart';

class AudioProbeService {
  final FfmpegLocator locator;
  AudioProbeService(this.locator);

  /// Returns the duration of [audioPath] in seconds, via ffprobe.
  Future<double> probeDurationSeconds(String audioPath) async {
    final paths = await locator.resolve();
    final result = await Process.run(paths.ffprobe, [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'csv=p=0',
      audioPath,
    ]);
    if (result.exitCode != 0) {
      throw Exception('ffprobe failed for $audioPath: ${result.stderr}');
    }
    final text = (result.stdout as String).trim();
    final value = double.tryParse(text);
    if (value == null) {
      throw Exception('Could not parse duration from ffprobe output: "$text"');
    }
    return value;
  }

  /// Returns [audioPath]'s technical details (codec, sample rate, bit depth,
  /// channels, bitrate, size, duration, title/artist tags), via ffprobe.
  Future<AudioInfo> probeInfo(String audioPath) async {
    final paths = await locator.resolve();
    final raw = await runFfprobeRaw(paths.ffprobe, [
      '-v',
      'error',
      '-show_format',
      '-show_streams',
      '-select_streams',
      'a:0',
      '-of',
      'json',
      audioPath,
    ]);
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw Exception('ffprobe could not read $audioPath');
    }
    if (decoded is! Map<String, dynamic> ||
        (decoded['streams'] as List?)?.isEmpty != false) {
      throw Exception('No audio stream found in $audioPath');
    }
    return AudioInfo.fromFfprobeJson(decoded);
  }
}

/// Utility for tests/CLI: run ffprobe and decode stdout as utf8 explicitly,
/// in case the platform default encoding differs.
Future<String> runFfprobeRaw(String ffprobePath, List<String> args) async {
  final process = await Process.start(ffprobePath, args);
  final stdoutBytes = await process.stdout.fold<List<int>>(
    <int>[],
    (acc, chunk) => acc..addAll(chunk),
  );
  await process.exitCode;
  return utf8.decode(stdoutBytes, allowMalformed: true);
}
