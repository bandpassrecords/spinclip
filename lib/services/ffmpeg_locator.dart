import 'dart:io';

class FfmpegNotFoundException implements Exception {
  final String binaryName;
  FfmpegNotFoundException(this.binaryName);

  @override
  String toString() =>
      '$binaryName was not found. Install it and ensure it is on your PATH, '
      'or set the FFMPEG_PATH environment variable to its directory.';
}

class FfmpegPaths {
  final String ffmpeg;
  final String ffprobe;
  const FfmpegPaths({required this.ffmpeg, required this.ffprobe});
}

/// Resolves the ffmpeg/ffprobe binaries to invoke, in order:
/// 1. A binary bundled next to the running executable (tools/ffmpeg[.exe]).
/// 2. The FFMPEG_PATH environment variable (a directory containing the binaries).
/// 3. PATH lookup.
class FfmpegLocator {
  FfmpegPaths? _cached;

  Future<FfmpegPaths> resolve() async {
    final cached = _cached;
    if (cached != null) return cached;

    final exeName = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
    final probeName = Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

    final bundledDir = Directory(
      '${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}tools',
    );
    final bundledFfmpeg = File('${bundledDir.path}${Platform.pathSeparator}$exeName');
    final bundledFfprobe = File('${bundledDir.path}${Platform.pathSeparator}$probeName');
    if (await bundledFfmpeg.exists() && await bundledFfprobe.exists()) {
      final result = FfmpegPaths(ffmpeg: bundledFfmpeg.path, ffprobe: bundledFfprobe.path);
      _cached = result;
      return result;
    }

    final envDir = Platform.environment['FFMPEG_PATH'];
    if (envDir != null && envDir.isNotEmpty) {
      final envFfmpeg = File('$envDir${Platform.pathSeparator}$exeName');
      final envFfprobe = File('$envDir${Platform.pathSeparator}$probeName');
      if (await envFfmpeg.exists() && await envFfprobe.exists()) {
        final result = FfmpegPaths(ffmpeg: envFfmpeg.path, ffprobe: envFfprobe.path);
        _cached = result;
        return result;
      }
    }

    final pathFfmpeg = await _probeOnPath(exeName);
    final pathFfprobe = await _probeOnPath(probeName);
    if (pathFfmpeg && pathFfprobe) {
      final result = FfmpegPaths(ffmpeg: exeName, ffprobe: probeName);
      _cached = result;
      return result;
    }

    throw FfmpegNotFoundException(pathFfmpeg ? probeName : exeName);
  }

  Future<bool> _probeOnPath(String binary) async {
    try {
      final result = await Process.run(binary, ['-version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
