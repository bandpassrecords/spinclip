import 'dart:convert';
import 'dart:io';

import 'ffmpeg_locator.dart';

class AudioProbeService {
  final FfmpegLocator locator;
  AudioProbeService(this.locator);

  /// Returns the duration of [audioPath] in seconds, via ffprobe.
  Future<double> probeDurationSeconds(String audioPath) async {
    final paths = await locator.resolve();
    final result = await Process.run(paths.ffprobe, [
      '-v', 'error',
      '-show_entries', 'format=duration',
      '-of', 'csv=p=0',
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
