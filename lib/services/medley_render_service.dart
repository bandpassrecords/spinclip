import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/platform_preset.dart';
import '../models/render_settings.dart';
import '../models/track.dart';
import 'concat_service.dart';
import 'video_render_service.dart';

class MedleyOutcome {
  final PlatformPreset preset;
  final RenderJobResult result;
  const MedleyOutcome(this.preset, this.result);
}

class MedleyProgress {
  final int presetIndex;
  final int presetCount;
  final PlatformPreset currentPreset;
  final int trackIndex;
  final int trackCount;
  final Track currentTrack;
  final double percentWithinTrack;
  const MedleyProgress({
    required this.presetIndex,
    required this.presetCount,
    required this.currentPreset,
    required this.trackIndex,
    required this.trackCount,
    required this.currentTrack,
    required this.percentWithinTrack,
  });
}

/// Renders one trimmed excerpt ("trecho") per track, then concatenates them
/// into a single combined video per selected preset - e.g. a release trailer
/// that plays a short piece of each song in turn. Each track's excerpt is
/// rendered as a normal preset-sized clip (same codec/pixel format across
/// all tracks), so the concat step is a fast, lossless stream copy.
class MedleyRenderService {
  final VideoRenderService videoRenderService;
  final ConcatService concatService;
  MedleyRenderService(this.videoRenderService, this.concatService);

  Future<List<MedleyOutcome>> renderMedley({
    required RenderSettings templateSettings,
    required List<Track> tracks,
    required String defaultImagePath,
    required List<PlatformPreset> presets,
    required String outputDirectory,
    String? qrAssetPath,
    bool useHardwareAcceleration = true,
    void Function(MedleyProgress progress)? onProgress,
  }) async {
    final outcomes = <MedleyOutcome>[];
    final tempDir = await Directory.systemTemp.createTemp('promo_medley_');

    try {
      for (var pi = 0; pi < presets.length; pi++) {
        final preset = presets[pi];
        final segmentPaths = <String>[];
        RenderJobResult? failure;

        for (var ti = 0; ti < tracks.length; ti++) {
          final track = tracks[ti];
          final segmentSettings = templateSettings.forTrack(
            track,
            defaultImagePath: defaultImagePath,
          );
          final segmentPath = p.join(
            tempDir.path,
            '${preset.id}_segment_$ti.mp4',
          );

          final result = await videoRenderService.render(
            settings: segmentSettings,
            preset: preset,
            outputPath: segmentPath,
            qrAssetPath: qrAssetPath,
            useHardwareAcceleration: useHardwareAcceleration,
            onProgress: (percent) {
              onProgress?.call(
                MedleyProgress(
                  presetIndex: pi,
                  presetCount: presets.length,
                  currentPreset: preset,
                  trackIndex: ti,
                  trackCount: tracks.length,
                  currentTrack: track,
                  percentWithinTrack: percent,
                ),
              );
            },
          );

          if (!result.success) {
            failure = result;
            break;
          }
          // Use the actual path VideoRenderService wrote to, not the
          // requested one - it rewrites the extension to .mov for lossless
          // (PCM) audio, since MP4 doesn't support that reliably.
          segmentPaths.add(result.outputPath ?? segmentPath);
        }

        if (failure != null) {
          outcomes.add(MedleyOutcome(preset, failure));
          continue;
        }

        // Match the segments' own container so concat's stream copy doesn't
        // have to remux PCM audio into an MP4 that can't hold it.
        final extension = p.extension(segmentPaths.first);
        final finalPath = p.join(
          outputDirectory,
          'medley_${preset.id}$extension',
        );
        try {
          await concatService.concat(segmentPaths, finalPath);
          outcomes.add(
            MedleyOutcome(
              preset,
              RenderJobResult(success: true, outputPath: finalPath),
            ),
          );
        } catch (e) {
          outcomes.add(
            MedleyOutcome(
              preset,
              RenderJobResult(success: false, errorMessage: e.toString()),
            ),
          );
        }
      }
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }

    return outcomes;
  }

  void cancel() => videoRenderService.cancel();
}
