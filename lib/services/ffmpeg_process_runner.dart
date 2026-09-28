import 'dart:async';
import 'dart:convert';
import 'dart:io';

class FfmpegRunResult {
  final int exitCode;
  final String stderrLog;
  const FfmpegRunResult({required this.exitCode, required this.stderrLog});

  bool get success => exitCode == 0;
}

/// Thin wrapper around Process.start for invoking ffmpeg: streams stdout
/// (progress pipe) and stderr (human-readable log) separately, and supports
/// cancellation by killing the subprocess.
class FfmpegProcessRunner {
  Process? _process;
  bool _cancelled = false;

  bool get isRunning => _process != null;

  Future<FfmpegRunResult> run({
    required String ffmpegPath,
    required List<String> args,
    void Function(Stream<List<int>> stdout)? onStdout,
    void Function(String line)? onStderrLine,
  }) async {
    _cancelled = false;
    final fullArgs = ['-progress', 'pipe:1', '-nostats', ...args];
    final process = await Process.start(ffmpegPath, fullArgs);
    _process = process;

    if (onStdout != null) {
      onStdout(process.stdout);
    } else {
      unawaited(process.stdout.drain());
    }

    final stderrBuffer = StringBuffer();
    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stderrBuffer.writeln(line);
          onStderrLine?.call(line);
        });

    final exitCode = await process.exitCode;
    await stderrSub.cancel();
    _process = null;

    if (_cancelled) {
      return FfmpegRunResult(
        exitCode: -1,
        stderrLog: 'Cancelled by user.\n${stderrBuffer.toString()}',
      );
    }
    return FfmpegRunResult(
      exitCode: exitCode,
      stderrLog: stderrBuffer.toString(),
    );
  }

  void cancel() {
    final process = _process;
    if (process != null) {
      _cancelled = true;
      process.kill(ProcessSignal.sigterm);
    }
  }
}
