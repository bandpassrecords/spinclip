/// Technical details of an audio file, as reported by ffprobe - shown next to
/// a picked song so the user can check they chose the right master (e.g. the
/// 24-bit WAV rather than an MP3 preview).
class AudioInfo {
  final double durationSeconds;

  /// Container, e.g. 'wav', 'flac', 'mp3'.
  final String formatName;

  /// ffprobe codec id, e.g. 'pcm_s16le', 'flac', 'mp3'.
  final String codecName;
  final int? sampleRate;
  final int? channels;

  /// Bits per sample for PCM/lossless audio; null for lossy codecs, where
  /// bit depth isn't meaningful.
  final int? bitDepth;

  /// Bits per second (the stream's, else the whole file's).
  final int? bitRate;
  final int? sizeBytes;
  final String? title;
  final String? artist;

  const AudioInfo({
    required this.durationSeconds,
    required this.formatName,
    required this.codecName,
    this.sampleRate,
    this.channels,
    this.bitDepth,
    this.bitRate,
    this.sizeBytes,
    this.title,
    this.artist,
  });

  static const _losslessCodecs = {'flac', 'alac', 'wavpack', 'ape', 'tta'};

  bool get isLossless =>
      codecName.startsWith('pcm_') || _losslessCodecs.contains(codecName);

  /// Parses `ffprobe -of json -show_format -show_streams` output for the
  /// first audio stream.
  factory AudioInfo.fromFfprobeJson(Map<String, dynamic> json) {
    final streams = (json['streams'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final stream = streams.firstWhere(
      (s) => s['codec_type'] == 'audio',
      orElse: () => streams.isNotEmpty ? streams.first : <String, dynamic>{},
    );
    final format = json['format'] as Map<String, dynamic>? ?? const {};
    final tags = {
      ...?(format['tags'] as Map?)?.map(
        (k, v) => MapEntry(k.toString().toLowerCase(), v.toString()),
      ),
      ...?(stream['tags'] as Map?)?.map(
        (k, v) => MapEntry(k.toString().toLowerCase(), v.toString()),
      ),
    };

    int? positiveInt(Object? v) {
      final n = v is num ? v.toInt() : int.tryParse('${v ?? ''}');
      return n != null && n > 0 ? n : null;
    }

    final codec = stream['codec_name'] as String? ?? 'unknown';
    final info = AudioInfo(
      durationSeconds:
          double.tryParse('${format['duration'] ?? stream['duration']}') ?? 0,
      formatName: (format['format_name'] as String? ?? '').split(',').first,
      codecName: codec,
      sampleRate: positiveInt(stream['sample_rate']),
      channels: positiveInt(stream['channels']),
      bitRate:
          positiveInt(stream['bit_rate']) ?? positiveInt(format['bit_rate']),
      sizeBytes: positiveInt(format['size']),
      title: _nonEmpty(tags['title']),
      artist: _nonEmpty(tags['artist']),
    );
    // FLAC reports its real depth in bits_per_raw_sample (bits_per_sample is
    // 0); PCM reports bits_per_sample. Lossy codecs report neither usefully.
    final depth =
        positiveInt(stream['bits_per_raw_sample']) ??
        positiveInt(stream['bits_per_sample']);
    return AudioInfo(
      durationSeconds: info.durationSeconds,
      formatName: info.formatName,
      codecName: info.codecName,
      sampleRate: info.sampleRate,
      channels: info.channels,
      bitDepth: info.isLossless ? depth : null,
      bitRate: info.bitRate,
      sizeBytes: info.sizeBytes,
      title: info.title,
      artist: info.artist,
    );
  }

  static String? _nonEmpty(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();
}
