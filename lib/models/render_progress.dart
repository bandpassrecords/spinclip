enum RenderPhase { idle, probing, rendering, done, error, cancelled }

class RenderProgress {
  final RenderPhase phase;
  final double percent; // 0.0 - 1.0
  final String? currentPresetName;
  final int? presetIndex;
  final int? presetCount;

  /// Set only in multi-song/medley modes, to show "song 2/5" alongside the preset progress.
  final String? currentTrackName;
  final int? trackIndex;
  final int? trackCount;

  final String? message;
  final String? outputPath;

  const RenderProgress({
    this.phase = RenderPhase.idle,
    this.percent = 0,
    this.currentPresetName,
    this.presetIndex,
    this.presetCount,
    this.currentTrackName,
    this.trackIndex,
    this.trackCount,
    this.message,
    this.outputPath,
  });

  RenderProgress copyWith({
    RenderPhase? phase,
    double? percent,
    String? currentPresetName,
    int? presetIndex,
    int? presetCount,
    String? currentTrackName,
    int? trackIndex,
    int? trackCount,
    String? message,
    String? outputPath,
  }) {
    return RenderProgress(
      phase: phase ?? this.phase,
      percent: percent ?? this.percent,
      currentPresetName: currentPresetName ?? this.currentPresetName,
      presetIndex: presetIndex ?? this.presetIndex,
      presetCount: presetCount ?? this.presetCount,
      currentTrackName: currentTrackName ?? this.currentTrackName,
      trackIndex: trackIndex ?? this.trackIndex,
      trackCount: trackCount ?? this.trackCount,
      message: message ?? this.message,
      outputPath: outputPath ?? this.outputPath,
    );
  }
}
