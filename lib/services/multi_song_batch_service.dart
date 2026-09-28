import 'package:path/path.dart' as p;

import '../models/platform_preset.dart';
import '../models/render_settings.dart';
import '../models/track.dart';
import 'video_render_service.dart';

class MultiSongJobOutcome {
  final Track track;
  final PlatformPreset preset;
  final RenderJobResult result;
  const MultiSongJobOutcome(this.track, this.preset, this.result);
}

class MultiSongProgress {
  final int trackIndex;
  final int trackCount;
  final int presetIndex;
  final int presetCount;
  final Track currentTrack;
  final PlatformPreset currentPreset;
  final double percentWithinJob;
  const MultiSongProgress({
    required this.trackIndex,
    required this.trackCount,
    required this.presetIndex,
    required this.presetCount,
    required this.currentTrack,
    required this.currentPreset,
    required this.percentWithinJob,
  });
}

/// Renders each track independently, once per selected platform preset, so
/// N songs x M presets produces N*M standalone output videos (one video per
/// song, not a combined medley - see MedleyRenderService for that).
class MultiSongBatchService {
  final VideoRenderService videoRenderService;
  MultiSongBatchService(this.videoRenderService);

  Future<List<MultiSongJobOutcome>> renderAll({
    required RenderSettings templateSettings,
    required List<Track> tracks,
    required String defaultImagePath,
    required List<PlatformPreset> presets,
    required String outputDirectory,
    String? qrAssetPath,
    bool useHardwareAcceleration = true,
    void Function(MultiSongProgress progress)? onProgress,
  }) async {
    final outcomes = <MultiSongJobOutcome>[];

    for (var ti = 0; ti < tracks.length; ti++) {
      final track = tracks[ti];
      final trackSettings = templateSettings.forTrack(
        track,
        defaultImagePath: defaultImagePath,
      );
      final baseName = p.basenameWithoutExtension(track.audioPath);

      for (var pi = 0; pi < presets.length; pi++) {
        final preset = presets[pi];
        final outputPath = p.join(
          outputDirectory,
          'output_${preset.id}_$baseName.mp4',
        );

        final result = await videoRenderService.render(
          settings: trackSettings,
          preset: preset,
          outputPath: outputPath,
          qrAssetPath: qrAssetPath,
          useHardwareAcceleration: useHardwareAcceleration,
          onProgress: (percent) {
            onProgress?.call(
              MultiSongProgress(
                trackIndex: ti,
                trackCount: tracks.length,
                presetIndex: pi,
                presetCount: presets.length,
                currentTrack: track,
                currentPreset: preset,
                percentWithinJob: percent,
              ),
            );
          },
        );

        outcomes.add(MultiSongJobOutcome(track, preset, result));
      }
    }

    return outcomes;
  }

  void cancel() => videoRenderService.cancel();
}
