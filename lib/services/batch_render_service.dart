import 'package:path/path.dart' as p;

import '../models/platform_preset.dart';
import '../models/render_settings.dart';
import 'video_render_service.dart';

class BatchProgress {
  final int presetIndex;
  final int presetCount;
  final PlatformPreset currentPreset;
  final double percentWithinPreset;
  const BatchProgress({
    required this.presetIndex,
    required this.presetCount,
    required this.currentPreset,
    required this.percentWithinPreset,
  });
}

class BatchJobOutcome {
  final PlatformPreset preset;
  final RenderJobResult result;
  const BatchJobOutcome(this.preset, this.result);
}

/// Runs VideoRenderService once per selected platform preset, sequentially
/// (simplest, avoids CPU contention between concurrent ffmpeg encodes).
class BatchRenderService {
  final VideoRenderService videoRenderService;
  BatchRenderService(this.videoRenderService);

  Future<List<BatchJobOutcome>> renderAll({
    required RenderSettings settings,
    required List<PlatformPreset> presets,
    required String outputDirectory,
    String? qrAssetPath,
    bool useHardwareAcceleration = true,
    void Function(BatchProgress progress)? onProgress,
  }) async {
    final outcomes = <BatchJobOutcome>[];

    for (var i = 0; i < presets.length; i++) {
      final preset = presets[i];
      final outputPath = p.join(outputDirectory, 'output_${preset.id}.mp4');

      final result = await videoRenderService.render(
        settings: settings,
        preset: preset,
        outputPath: outputPath,
        qrAssetPath: qrAssetPath,
        useHardwareAcceleration: useHardwareAcceleration,
        onProgress: (percent) {
          onProgress?.call(BatchProgress(
            presetIndex: i,
            presetCount: presets.length,
            currentPreset: preset,
            percentWithinPreset: percent,
          ));
        },
      );

      outcomes.add(BatchJobOutcome(preset, result));
    }

    return outcomes;
  }

  void cancel() => videoRenderService.cancel();
}
