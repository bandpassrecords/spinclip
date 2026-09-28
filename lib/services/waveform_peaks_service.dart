import 'dart:io';
import 'dart:typed_data';

import 'ffmpeg_locator.dart';

/// Extracts a peak-amplitude envelope from an audio file for waveform
/// display. Unlike a DAW that needs to parse WAV/MP3/FLAC headers itself,
/// this app already leans on ffmpeg for everything else, so it's simplest to
/// have ffmpeg decode any input format straight to raw mono PCM and bin that
/// - no per-format parser needed.
class WaveformPeaksService {
  final FfmpegLocator locator;
  WaveformPeaksService(this.locator);

  /// Returns [bucketCount] peak values (0.0-1.0, each the max absolute
  /// sample amplitude in that time slice) spanning the whole file.
  Future<List<double>> extractPeaks(
    String audioPath, {
    int bucketCount = 400,
  }) async {
    final paths = await locator.resolve();
    const sampleRate =
        11025; // low rate is plenty for a visual envelope, keeps decoding fast

    final result = await Process.run(paths.ffmpeg, [
      '-v',
      'error',
      '-i',
      audioPath,
      '-f',
      's16le',
      '-acodec',
      'pcm_s16le',
      '-ac',
      '1',
      '-ar',
      '$sampleRate',
      'pipe:1',
    ], stdoutEncoding: null);

    if (result.exitCode != 0) {
      throw Exception('ffmpeg PCM decode failed: ${result.stderr}');
    }

    final bytes = result.stdout as Uint8List;
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return List.filled(bucketCount, 0.0);

    final samples = Int16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      sampleCount,
    );
    final samplesPerBucket = (sampleCount / bucketCount).ceil().clamp(
      1,
      sampleCount,
    );

    final peaks = <double>[];
    for (var bucket = 0; bucket < bucketCount; bucket++) {
      final start = bucket * samplesPerBucket;
      if (start >= sampleCount) {
        peaks.add(0.0);
        continue;
      }
      final end = (start + samplesPerBucket).clamp(0, sampleCount);
      var maxAbs = 0;
      for (var i = start; i < end; i++) {
        final v = samples[i].abs();
        if (v > maxAbs) maxAbs = v;
      }
      peaks.add(maxAbs / 32768.0);
    }
    return peaks;
  }
}
