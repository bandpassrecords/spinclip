import 'dart:io';

import 'package:path/path.dart' as p;

import 'ffmpeg_locator.dart';

/// Concatenates already-encoded video files (via ffmpeg's concat demuxer,
/// stream-copy, no re-encode) into a single output file. Every input must
/// share the same codec/resolution/pixel format - true here because they're
/// all produced by the same FiltergraphBuilder/VideoRenderService encode
/// settings for a given platform preset.
class ConcatService {
  final FfmpegLocator locator;
  ConcatService(this.locator);

  Future<void> concat(List<String> inputPaths, String outputPath) async {
    final paths = await locator.resolve();

    final listFile = File(
      p.join(
        Directory.systemTemp.path,
        'promo_concat_${DateTime.now().microsecondsSinceEpoch}.txt',
      ),
    );
    final content = inputPaths
        .map((path) => "file '${_escape(path)}'")
        .join('\n');
    await listFile.writeAsString(content);

    try {
      final result = await Process.run(paths.ffmpeg, [
        '-y',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        listFile.path,
        '-c',
        'copy',
        outputPath,
      ]);
      if (result.exitCode != 0) {
        throw Exception('ffmpeg concat failed: ${result.stderr}');
      }
    } finally {
      if (await listFile.exists()) {
        await listFile.delete();
      }
    }
  }

  String _escape(String path) => path.replaceAll("'", r"'\''");
}
