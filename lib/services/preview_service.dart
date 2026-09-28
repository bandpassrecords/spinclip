import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/render_settings.dart';
import 'audio_probe_service.dart';
import 'ffmpeg_locator.dart';
import 'ffmpeg_process_runner.dart';
import 'filtergraph_builder.dart';

class PreviewResult {
  final bool success;
  final String? imagePath;
  final String? errorMessage;
  const PreviewResult({required this.success, this.imagePath, this.errorMessage});
}

/// Renders a single still frame from the actual filter graph, so what the
/// user sees before committing to a full render is pixel-accurate, not an
/// illustrative mockup. Typically takes well under a second, since it's one
/// frame rather than an encoded video.
class PreviewService {
  final FfmpegLocator locator;
  final AudioProbeService audioProbe;
  final FiltergraphBuilder builder;

  PreviewService({
    required this.locator,
    required this.audioProbe,
    this.builder = const FiltergraphBuilder(),
  });

  Future<PreviewResult> generatePreview({
    required RenderSettings settings,
    required int width,
    required int height,
    String? qrAssetPath,
    double? seekSeconds,
  }) async {
    if (!await File(settings.imagePath).exists()) {
      return PreviewResult(success: false, errorMessage: 'Cover image not found: ${settings.imagePath}');
    }
    if (!await File(settings.audioPath).exists()) {
      return PreviewResult(success: false, errorMessage: 'Audio file not found: ${settings.audioPath}');
    }

    final FfmpegPaths paths;
    try {
      paths = await locator.resolve();
    } on FfmpegNotFoundException catch (e) {
      return PreviewResult(success: false, errorMessage: e.toString());
    }

    double audioDuration;
    try {
      audioDuration = await audioProbe.probeDurationSeconds(settings.audioPath);
    } catch (e) {
      return PreviewResult(success: false, errorMessage: 'Failed to probe audio: $e');
    }

    final outputPath = p.join(
      Directory.systemTemp.path,
      'promo_preview_${DateTime.now().microsecondsSinceEpoch}.png',
    );

    final args = builder.buildPreviewFrameArgs(
      settings: settings,
      width: width,
      height: height,
      audioDurationSeconds: audioDuration,
      outputPngPath: outputPath,
      qrAssetPath: qrAssetPath,
      seekSeconds: seekSeconds,
    );

    final result = await FfmpegProcessRunner().run(ffmpegPath: paths.ffmpeg, args: args);
    if (!result.success) {
      return PreviewResult(success: false, errorMessage: result.stderrLog);
    }
    return PreviewResult(success: true, imagePath: outputPath);
  }
}
