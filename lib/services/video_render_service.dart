import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/platform_preset.dart';
import '../models/render_settings.dart';
import 'audio_probe_service.dart';
import 'encoder_detector.dart';
import 'ffmpeg_locator.dart';
import 'ffmpeg_process_runner.dart';
import 'ffmpeg_progress_parser.dart';
import 'filtergraph_builder.dart';

class RenderJobResult {
  final bool success;
  final String? outputPath;
  final String? errorMessage;
  const RenderJobResult({
    required this.success,
    this.outputPath,
    this.errorMessage,
  });
}

/// Orchestrates a single render job: validate inputs, probe audio duration,
/// build the ffmpeg command, run it, and report the outcome. Shared by the
/// CLI and the GUI, and looped over by BatchRenderService for multi-preset runs.
class VideoRenderService {
  final FfmpegLocator locator;
  final AudioProbeService audioProbe;
  final FiltergraphBuilder builder;
  final FfmpegProcessRunner runner;
  final EncoderDetector encoderDetector;

  VideoRenderService({
    required this.locator,
    required this.audioProbe,
    this.builder = const FiltergraphBuilder(),
    FfmpegProcessRunner? runner,
    EncoderDetector? encoderDetector,
  }) : runner = runner ?? FfmpegProcessRunner(),
       encoderDetector = encoderDetector ?? EncoderDetector(locator);

  Future<RenderJobResult> render({
    required RenderSettings settings,
    required PlatformPreset preset,
    required String outputPath,
    String? qrAssetPath,
    bool useHardwareAcceleration = true,
    void Function(double percent)? onProgress,
  }) async {
    if (!await File(settings.imagePath).exists()) {
      return RenderJobResult(
        success: false,
        errorMessage: 'Cover image not found: ${settings.imagePath}',
      );
    }
    if (!await File(settings.audioPath).exists()) {
      return RenderJobResult(
        success: false,
        errorMessage: 'Audio file not found: ${settings.audioPath}',
      );
    }

    // Spotify Canvas strictly requires an MP4/AAC file - override the
    // lossless-audio preference for that one preset's job only.
    final effectiveSettings =
        preset.id == 'spotify_canvas' && settings.losslessAudio
        ? settings.copyWith(losslessAudio: false)
        : settings;
    // PCM audio needs a .mov container; MP4 doesn't support it reliably.
    final effectiveOutputPath = p.setExtension(
      outputPath,
      effectiveSettings.losslessAudio ? '.mov' : '.mp4',
    );

    final FfmpegPaths paths;
    try {
      paths = await locator.resolve();
    } on FfmpegNotFoundException catch (e) {
      return RenderJobResult(success: false, errorMessage: e.toString());
    }

    late final double audioDuration;
    try {
      audioDuration = await audioProbe.probeDurationSeconds(
        effectiveSettings.audioPath,
      );
    } catch (e) {
      return RenderJobResult(
        success: false,
        errorMessage: 'Failed to probe audio: $e',
      );
    }

    final effectiveDuration =
        preset.fixedLoopSeconds ??
        (effectiveSettings.fullDuration
            ? audioDuration
            : (effectiveSettings.trimDurationSeconds ??
                  (audioDuration - effectiveSettings.trimStartSeconds)));

    final outputDir = Directory(File(effectiveOutputPath).parent.path);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final videoCodec = await encoderDetector.resolveVideoCodec(
      preferHardware: useHardwareAcceleration,
    );

    var result = await _runOnce(
      settings: effectiveSettings,
      preset: preset,
      outputPath: effectiveOutputPath,
      qrAssetPath: qrAssetPath,
      videoCodec: videoCodec,
      audioDuration: audioDuration,
      effectiveDuration: effectiveDuration,
      paths: paths,
      onProgress: onProgress,
    );

    // A hardware encoder can fail for reasons software-only detection can't
    // predict (driver quirks, a busy GPU, an unsupported resolution) - retry
    // once with libx264 rather than failing the whole job.
    if (!result.success && videoCodec != 'libx264') {
      result = await _runOnce(
        settings: effectiveSettings,
        preset: preset,
        outputPath: effectiveOutputPath,
        qrAssetPath: qrAssetPath,
        videoCodec: 'libx264',
        audioDuration: audioDuration,
        effectiveDuration: effectiveDuration,
        paths: paths,
        onProgress: onProgress,
      );
    }

    return result;
  }

  Future<RenderJobResult> _runOnce({
    required RenderSettings settings,
    required PlatformPreset preset,
    required String outputPath,
    String? qrAssetPath,
    required String videoCodec,
    required double audioDuration,
    required double effectiveDuration,
    required FfmpegPaths paths,
    void Function(double percent)? onProgress,
  }) async {
    final args = builder.buildArgs(
      settings: settings,
      width: preset.width,
      height: preset.height,
      audioDurationSeconds: audioDuration,
      outputPath: outputPath,
      qrAssetPath: qrAssetPath,
      fixedLoopSeconds: preset.fixedLoopSeconds,
      videoCodec: videoCodec,
    );

    final parser = FfmpegProgressParser(
      totalDurationSeconds: effectiveDuration,
      onProgress: (p) => onProgress?.call(p),
      onEnd: () {},
    );

    final result = await runner.run(
      ffmpegPath: paths.ffmpeg,
      args: args,
      onStdout: (stdout) => parser.listen(stdout),
    );

    if (!result.success) {
      // Clean up partial output on failure/cancellation.
      final partial = File(outputPath);
      if (await partial.exists()) {
        try {
          await partial.delete();
        } catch (_) {}
      }
      return RenderJobResult(success: false, errorMessage: result.stderrLog);
    }

    return RenderJobResult(success: true, outputPath: outputPath);
  }

  void cancel() => runner.cancel();
}
