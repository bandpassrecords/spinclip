import 'dart:async';
import 'dart:convert';

/// Parses ffmpeg's `-progress pipe:1` machine-readable key=value stream
/// (out_time_ms=, progress=end, etc.) into a 0.0-1.0 fraction against a
/// known total duration.
class FfmpegProgressParser {
  final double totalDurationSeconds;
  final void Function(double percent) onProgress;
  final void Function() onEnd;

  FfmpegProgressParser({
    required this.totalDurationSeconds,
    required this.onProgress,
    required this.onEnd,
  });

  StreamSubscription<String> listen(Stream<List<int>> progressStdout) {
    return progressStdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine);
  }

  void _handleLine(String line) {
    final eq = line.indexOf('=');
    if (eq == -1) return;
    final key = line.substring(0, eq).trim();
    final value = line.substring(eq + 1).trim();

    if (key == 'out_time_ms' || key == 'out_time_us') {
      final micros = int.tryParse(value);
      if (micros != null && totalDurationSeconds > 0) {
        final seconds = micros / 1000000.0;
        final percent = (seconds / totalDurationSeconds).clamp(0.0, 1.0);
        onProgress(percent);
      }
    } else if (key == 'progress' && value == 'end') {
      onProgress(1.0);
      onEnd();
    }
  }
}
