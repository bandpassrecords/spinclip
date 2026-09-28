/// One song's input to a render job. In single-song mode there's one Track;
/// in multi-song batch mode each Track produces its own independent output;
/// in medley mode each Track contributes one trimmed excerpt ("trecho") that
/// gets concatenated with the others into a single combined video.
class Track {
  final String audioPath;

  /// Falls back to the release's shared cover image when null.
  final String? imagePath;

  final bool fullDuration;
  final double trimStartSeconds;
  final double? trimDurationSeconds;

  /// Optional per-track text overlay (e.g. song title), overriding the
  /// shared RenderSettings.textContent for this track's segment only.
  final String? title;

  const Track({
    required this.audioPath,
    this.imagePath,
    this.fullDuration = true,
    this.trimStartSeconds = 0,
    this.trimDurationSeconds,
  }) : title = null;

  const Track.withTitle({
    required this.audioPath,
    this.imagePath,
    this.fullDuration = true,
    this.trimStartSeconds = 0,
    this.trimDurationSeconds,
    this.title,
  });

  Track copyWith({
    String? audioPath,
    String? imagePath,
    bool? fullDuration,
    double? trimStartSeconds,
    double? trimDurationSeconds,
    String? title,
  }) {
    return Track.withTitle(
      audioPath: audioPath ?? this.audioPath,
      imagePath: imagePath ?? this.imagePath,
      fullDuration: fullDuration ?? this.fullDuration,
      trimStartSeconds: trimStartSeconds ?? this.trimStartSeconds,
      trimDurationSeconds: trimDurationSeconds ?? this.trimDurationSeconds,
      title: title ?? this.title,
    );
  }
}
