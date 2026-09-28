import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/element_transform.dart';
import '../models/platform_preset.dart';
import '../models/qr_caption_position.dart';
import '../models/release_mode.dart';
import '../models/render_progress.dart';
import '../models/render_settings.dart';
import '../models/track.dart';
import '../models/visualizer_placement.dart';
import '../models/visualizer_style.dart';
import '../services/audio_probe_service.dart';
import '../services/batch_render_service.dart';
import '../services/concat_service.dart';
import '../services/ffmpeg_locator.dart';
import '../services/medley_render_service.dart';
import '../services/multi_song_batch_service.dart';
import '../services/preview_service.dart';
import '../services/qr_code_service.dart';
import '../services/video_render_service.dart';

class DraftSettings {
  final ReleaseMode releaseMode;
  final String? imagePath;
  final String? audioPath;

  /// Probed length of `audioPath` (single mode), kept in sync by
  /// DraftSettingsNotifier.setAudioPath so the trim range slider has real
  /// bounds instead of a guessed default.
  final double? probedAudioDurationSeconds;

  final List<Track> tracks;
  final double snippetDurationSeconds;
  final VisualizerPlacement placement;
  final VisualizerStyle style;
  final String visualizerColorHex;
  final double blurRadius;
  final double visualizerSmoothness;
  final bool showCover;
  final double coverSizeFraction;
  final ElementTransform coverTransform;
  final bool showLogo;
  final String? logoImagePath;
  final ElementTransform logoTransform;
  final bool showText;
  final String textContent;
  final ElementTransform textTransform;
  final bool showQrCode;
  final String qrCodeContent;
  final String qrCaptionText;
  final QrCaptionPosition qrCaptionPosition;
  final ElementTransform qrTransform;
  final double fadeInSeconds;
  final double fadeOutSeconds;
  final bool fullDuration;
  final double trimStartSeconds;
  final double? trimDurationSeconds;
  final Set<String> selectedPresetIds;
  final String? outputDirectory;
  final bool useHardwareAcceleration;
  final bool losslessAudio;
  final bool vintageEffect;

  const DraftSettings({
    this.releaseMode = ReleaseMode.single,
    this.imagePath,
    this.audioPath,
    this.probedAudioDurationSeconds,
    this.tracks = const [],
    this.snippetDurationSeconds = 8,
    this.placement = VisualizerPlacement.bottomBand,
    this.style = VisualizerStyle.bars,
    this.visualizerColorHex = '0x33CCFF',
    this.blurRadius = 20,
    this.visualizerSmoothness = 0.5,
    this.showCover = true,
    this.coverSizeFraction = 0.82,
    this.coverTransform = ElementTransform.center,
    this.showLogo = false,
    this.logoImagePath,
    this.logoTransform = ElementTransform.bottomRight,
    this.showText = false,
    this.textContent = '',
    this.textTransform = ElementTransform.bottomCenter,
    this.showQrCode = false,
    this.qrCodeContent = '',
    this.qrCaptionText = '',
    this.qrCaptionPosition = QrCaptionPosition.below,
    this.qrTransform = ElementTransform.bottomLeft,
    this.fadeInSeconds = 0,
    this.fadeOutSeconds = 0,
    this.fullDuration = true,
    this.trimStartSeconds = 0,
    this.trimDurationSeconds,
    this.selectedPresetIds = const {'youtube'},
    this.outputDirectory,
    this.useHardwareAcceleration = true,
    this.losslessAudio = true,
    this.vintageEffect = false,
  });

  bool get isReadyToRender {
    if (imagePath == null || selectedPresetIds.isEmpty) return false;
    switch (releaseMode) {
      case ReleaseMode.single:
        return audioPath != null;
      case ReleaseMode.multiSong:
        return tracks.isNotEmpty;
      case ReleaseMode.medley:
        return tracks.length >= 2;
    }
  }

  /// Only meaningful in single mode - multi-song/medley build per-track
  /// RenderSettings via RenderSettings.forTrack instead.
  RenderSettings toRenderSettings() {
    return RenderSettings(
      imagePath: imagePath!,
      audioPath: audioPath!,
      placement: placement,
      style: style,
      visualizerColorHex: visualizerColorHex,
      blurRadius: blurRadius,
      visualizerSmoothness: visualizerSmoothness,
      showCover: showCover,
      coverSizeFraction: coverSizeFraction,
      coverTransform: coverTransform,
      showLogo: showLogo,
      logoImagePath: logoImagePath,
      logoTransform: logoTransform,
      showText: showText,
      textContent: textContent,
      textTransform: textTransform,
      showQrCode: showQrCode,
      qrCodeContent: qrCodeContent,
      qrCaptionText: qrCaptionText,
      qrCaptionPosition: qrCaptionPosition,
      qrTransform: qrTransform,
      fadeInSeconds: fadeInSeconds,
      fadeOutSeconds: fadeOutSeconds,
      fullDuration: fullDuration,
      trimStartSeconds: trimStartSeconds,
      trimDurationSeconds: trimDurationSeconds,
      losslessAudio: losslessAudio,
      vintageEffect: vintageEffect,
    );
  }

  /// The shared template (placement/style/color/blur/logo/text/QR/fades)
  /// used as a base for each track's RenderSettings in multi-song/medley mode.
  RenderSettings toTemplateSettings() {
    return RenderSettings(
      imagePath: imagePath!,
      audioPath: '',
      placement: placement,
      style: style,
      visualizerColorHex: visualizerColorHex,
      blurRadius: blurRadius,
      visualizerSmoothness: visualizerSmoothness,
      showCover: showCover,
      coverSizeFraction: coverSizeFraction,
      coverTransform: coverTransform,
      showLogo: showLogo,
      logoImagePath: logoImagePath,
      logoTransform: logoTransform,
      showText: showText,
      textContent: textContent,
      textTransform: textTransform,
      showQrCode: showQrCode,
      qrCodeContent: qrCodeContent,
      qrCaptionText: qrCaptionText,
      qrCaptionPosition: qrCaptionPosition,
      qrTransform: qrTransform,
      fadeInSeconds: fadeInSeconds,
      fadeOutSeconds: fadeOutSeconds,
      losslessAudio: losslessAudio,
      vintageEffect: vintageEffect,
    );
  }

  List<PlatformPreset> get selectedPresets =>
      PlatformPreset.all.where((preset) => selectedPresetIds.contains(preset.id)).toList();

  DraftSettings copyWith({
    ReleaseMode? releaseMode,
    String? imagePath,
    String? audioPath,
    double? probedAudioDurationSeconds,
    List<Track>? tracks,
    double? snippetDurationSeconds,
    VisualizerPlacement? placement,
    VisualizerStyle? style,
    String? visualizerColorHex,
    double? blurRadius,
    double? visualizerSmoothness,
    bool? showCover,
    double? coverSizeFraction,
    ElementTransform? coverTransform,
    bool? showLogo,
    String? logoImagePath,
    ElementTransform? logoTransform,
    bool? showText,
    String? textContent,
    ElementTransform? textTransform,
    bool? showQrCode,
    String? qrCodeContent,
    String? qrCaptionText,
    QrCaptionPosition? qrCaptionPosition,
    ElementTransform? qrTransform,
    double? fadeInSeconds,
    double? fadeOutSeconds,
    bool? fullDuration,
    double? trimStartSeconds,
    double? trimDurationSeconds,
    Set<String>? selectedPresetIds,
    String? outputDirectory,
    bool? useHardwareAcceleration,
    bool? losslessAudio,
    bool? vintageEffect,
  }) {
    return DraftSettings(
      releaseMode: releaseMode ?? this.releaseMode,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      probedAudioDurationSeconds: probedAudioDurationSeconds ?? this.probedAudioDurationSeconds,
      tracks: tracks ?? this.tracks,
      snippetDurationSeconds: snippetDurationSeconds ?? this.snippetDurationSeconds,
      placement: placement ?? this.placement,
      style: style ?? this.style,
      visualizerColorHex: visualizerColorHex ?? this.visualizerColorHex,
      blurRadius: blurRadius ?? this.blurRadius,
      visualizerSmoothness: visualizerSmoothness ?? this.visualizerSmoothness,
      showCover: showCover ?? this.showCover,
      coverSizeFraction: coverSizeFraction ?? this.coverSizeFraction,
      coverTransform: coverTransform ?? this.coverTransform,
      showLogo: showLogo ?? this.showLogo,
      logoImagePath: logoImagePath ?? this.logoImagePath,
      logoTransform: logoTransform ?? this.logoTransform,
      showText: showText ?? this.showText,
      textContent: textContent ?? this.textContent,
      textTransform: textTransform ?? this.textTransform,
      showQrCode: showQrCode ?? this.showQrCode,
      qrCodeContent: qrCodeContent ?? this.qrCodeContent,
      qrCaptionText: qrCaptionText ?? this.qrCaptionText,
      qrCaptionPosition: qrCaptionPosition ?? this.qrCaptionPosition,
      qrTransform: qrTransform ?? this.qrTransform,
      fadeInSeconds: fadeInSeconds ?? this.fadeInSeconds,
      fadeOutSeconds: fadeOutSeconds ?? this.fadeOutSeconds,
      fullDuration: fullDuration ?? this.fullDuration,
      trimStartSeconds: trimStartSeconds ?? this.trimStartSeconds,
      trimDurationSeconds: trimDurationSeconds ?? this.trimDurationSeconds,
      selectedPresetIds: selectedPresetIds ?? this.selectedPresetIds,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      useHardwareAcceleration: useHardwareAcceleration ?? this.useHardwareAcceleration,
      losslessAudio: losslessAudio ?? this.losslessAudio,
      vintageEffect: vintageEffect ?? this.vintageEffect,
    );
  }
}

class DraftSettingsNotifier extends Notifier<DraftSettings> {
  @override
  DraftSettings build() => const DraftSettings();

  void setReleaseMode(ReleaseMode mode) => state = state.copyWith(releaseMode: mode);
  void setImagePath(String path) => state = state.copyWith(imagePath: path);

  void setAudioPath(String path) {
    state = state.copyWith(audioPath: path);
    _probeAudioDuration(path);
  }

  /// Fire-and-forget: updates probedAudioDurationSeconds once ffprobe
  /// resolves, so the trim range slider gets real bounds instead of a
  /// guessed default. Silently leaves the previous value on failure -
  /// the render itself will surface a clearer error if the file is invalid.
  Future<void> _probeAudioDuration(String path) async {
    try {
      final locator = FfmpegLocator();
      final duration = await AudioProbeService(locator).probeDurationSeconds(path);
      if (state.audioPath == path) {
        state = state.copyWith(probedAudioDurationSeconds: duration);
      }
    } catch (_) {}
  }

  void setOutputDirectory(String path) => state = state.copyWith(outputDirectory: path);
  void setSnippetDuration(double v) => state = state.copyWith(snippetDurationSeconds: v);
  void setUseHardwareAcceleration(bool v) => state = state.copyWith(useHardwareAcceleration: v);
  void setLosslessAudio(bool v) => state = state.copyWith(losslessAudio: v);
  void setVintageEffect(bool v) => state = state.copyWith(vintageEffect: v);

  void addTracks(List<String> audioPaths) {
    final isMedley = state.releaseMode == ReleaseMode.medley;
    state = state.copyWith(tracks: [
      ...state.tracks,
      for (final audioPath in audioPaths)
        Track(
          audioPath: audioPath,
          fullDuration: !isMedley,
          trimDurationSeconds: isMedley ? state.snippetDurationSeconds : null,
        ),
    ]);
  }

  void removeTrackAt(int index) {
    final next = [...state.tracks]..removeAt(index);
    state = state.copyWith(tracks: next);
  }

  void updateTrackAt(int index, Track track) {
    final next = [...state.tracks];
    next[index] = track;
    state = state.copyWith(tracks: next);
  }
  void setPlacement(VisualizerPlacement v) => state = state.copyWith(placement: v);
  void setStyle(VisualizerStyle v) => state = state.copyWith(style: v);
  void setColor(String hex) => state = state.copyWith(visualizerColorHex: hex);
  void setBlurRadius(double v) => state = state.copyWith(blurRadius: v);
  void setShowCover(bool v) => state = state.copyWith(showCover: v);
  void setCoverSizeFraction(double v) => state = state.copyWith(coverSizeFraction: v);
  void setCoverTransform(ElementTransform v) => state = state.copyWith(coverTransform: v);
  void setShowLogo(bool v) => state = state.copyWith(showLogo: v);
  void setLogoImagePath(String? path) => state = state.copyWith(logoImagePath: path);
  void setLogoTransform(ElementTransform v) => state = state.copyWith(logoTransform: v);
  void setShowText(bool v) => state = state.copyWith(showText: v);
  void setTextContent(String v) => state = state.copyWith(textContent: v);
  void setTextTransform(ElementTransform v) => state = state.copyWith(textTransform: v);
  void setShowQrCode(bool v) => state = state.copyWith(showQrCode: v);
  void setQrCodeContent(String v) => state = state.copyWith(qrCodeContent: v);
  void setQrCaptionText(String v) => state = state.copyWith(qrCaptionText: v);
  void setQrCaptionPosition(QrCaptionPosition v) => state = state.copyWith(qrCaptionPosition: v);
  void setQrTransform(ElementTransform v) => state = state.copyWith(qrTransform: v);

  void resetTransforms() {
    state = state.copyWith(
      coverTransform: ElementTransform.center,
      logoTransform: ElementTransform.bottomRight,
      textTransform: ElementTransform.bottomCenter,
      qrTransform: ElementTransform.bottomLeft,
    );
  }
  void setFadeInSeconds(double v) => state = state.copyWith(fadeInSeconds: v);
  void setFadeOutSeconds(double v) => state = state.copyWith(fadeOutSeconds: v);
  void setVisualizerSmoothness(double v) => state = state.copyWith(visualizerSmoothness: v);
  void setFullDuration(bool v) => state = state.copyWith(fullDuration: v);
  void setTrimStart(double v) => state = state.copyWith(trimStartSeconds: v);
  void setTrimDuration(double? v) => state = state.copyWith(trimDurationSeconds: v);

  void togglePreset(String presetId, bool selected) {
    final next = {...state.selectedPresetIds};
    if (selected) {
      next.add(presetId);
    } else {
      next.remove(presetId);
    }
    state = state.copyWith(selectedPresetIds: next);
  }
}

final draftSettingsProvider = NotifierProvider<DraftSettingsNotifier, DraftSettings>(
  DraftSettingsNotifier.new,
);

class RenderJobNotifier extends Notifier<RenderProgress> {
  late final FfmpegLocator _locator;
  late final VideoRenderService _videoRenderService;
  late final BatchRenderService _batchRenderService;
  late final MultiSongBatchService _multiSongBatchService;
  late final MedleyRenderService _medleyRenderService;
  late final QrCodeService _qrCodeService;

  @override
  RenderProgress build() {
    _locator = FfmpegLocator();
    _videoRenderService = VideoRenderService(locator: _locator, audioProbe: AudioProbeService(_locator));
    _batchRenderService = BatchRenderService(_videoRenderService);
    _multiSongBatchService = MultiSongBatchService(_videoRenderService);
    _medleyRenderService = MedleyRenderService(_videoRenderService, ConcatService(_locator));
    _qrCodeService = QrCodeService();
    return const RenderProgress();
  }

  Future<void> startRender() async {
    final draft = ref.read(draftSettingsProvider);
    if (!draft.isReadyToRender) {
      state = state.copyWith(
        phase: RenderPhase.error,
        message: 'Select a cover image, the required song(s), and at least one platform first.',
      );
      return;
    }

    state = const RenderProgress(phase: RenderPhase.probing);

    final outputDir = draft.outputDirectory ?? await _defaultOutputDirectory();
    final presets = draft.selectedPresets;

    // Generated once per render session (content doesn't vary per preset or
    // track) and reused across every job in the batch.
    String? qrAssetPath;
    if (draft.showQrCode && draft.qrCodeContent.trim().isNotEmpty) {
      qrAssetPath = await _qrCodeService.generateQrPng(
        content: draft.qrCodeContent.trim(),
        sizePx: 512,
        captionPosition: draft.qrCaptionPosition,
        captionText: draft.qrCaptionText,
      );
    }

    state = state.copyWith(phase: RenderPhase.rendering, presetCount: presets.length, presetIndex: 0);

    switch (draft.releaseMode) {
      case ReleaseMode.single:
        await _runSingle(draft, presets, outputDir, qrAssetPath);
        break;
      case ReleaseMode.multiSong:
        await _runMultiSong(draft, presets, outputDir, qrAssetPath);
        break;
      case ReleaseMode.medley:
        await _runMedley(draft, presets, outputDir, qrAssetPath);
        break;
    }
  }

  Future<void> _runSingle(
    DraftSettings draft,
    List<PlatformPreset> presets,
    String outputDir,
    String? qrAssetPath,
  ) async {
    final settings = draft.toRenderSettings();
    final outcomes = await _batchRenderService.renderAll(
      settings: settings,
      presets: presets,
      outputDirectory: outputDir,
      qrAssetPath: qrAssetPath,
      useHardwareAcceleration: draft.useHardwareAcceleration,
      onProgress: (progress) {
        state = state.copyWith(
          phase: RenderPhase.rendering,
          percent: progress.percentWithinPreset,
          presetIndex: progress.presetIndex,
          presetCount: progress.presetCount,
          currentPresetName: progress.currentPreset.name,
        );
      },
    );

    final failed = outcomes.where((o) => !o.result.success).toList();
    if (failed.isNotEmpty) {
      state = state.copyWith(
        phase: RenderPhase.error,
        message: failed.map((f) => '${f.preset.name}: ${f.result.errorMessage}').join('\n'),
      );
    } else {
      state = state.copyWith(phase: RenderPhase.done, outputPath: outputDir, percent: 1.0);
    }
  }

  Future<void> _runMultiSong(
    DraftSettings draft,
    List<PlatformPreset> presets,
    String outputDir,
    String? qrAssetPath,
  ) async {
    final template = draft.toTemplateSettings();
    final outcomes = await _multiSongBatchService.renderAll(
      templateSettings: template,
      tracks: draft.tracks,
      defaultImagePath: draft.imagePath!,
      presets: presets,
      outputDirectory: outputDir,
      qrAssetPath: qrAssetPath,
      useHardwareAcceleration: draft.useHardwareAcceleration,
      onProgress: (progress) {
        state = state.copyWith(
          phase: RenderPhase.rendering,
          percent: progress.percentWithinJob,
          presetIndex: progress.presetIndex,
          presetCount: progress.presetCount,
          currentPresetName: progress.currentPreset.name,
          trackIndex: progress.trackIndex,
          trackCount: progress.trackCount,
          currentTrackName: progress.currentTrack.audioPath,
        );
      },
    );

    final failed = outcomes.where((o) => !o.result.success).toList();
    if (failed.isNotEmpty) {
      state = state.copyWith(
        phase: RenderPhase.error,
        message: failed.map((f) => '${f.track.audioPath} / ${f.preset.name}: ${f.result.errorMessage}').join('\n'),
      );
    } else {
      state = state.copyWith(phase: RenderPhase.done, outputPath: outputDir, percent: 1.0);
    }
  }

  Future<void> _runMedley(
    DraftSettings draft,
    List<PlatformPreset> presets,
    String outputDir,
    String? qrAssetPath,
  ) async {
    final template = draft.toTemplateSettings();
    final outcomes = await _medleyRenderService.renderMedley(
      templateSettings: template,
      tracks: draft.tracks,
      defaultImagePath: draft.imagePath!,
      presets: presets,
      outputDirectory: outputDir,
      qrAssetPath: qrAssetPath,
      useHardwareAcceleration: draft.useHardwareAcceleration,
      onProgress: (progress) {
        state = state.copyWith(
          phase: RenderPhase.rendering,
          percent: progress.percentWithinTrack,
          presetIndex: progress.presetIndex,
          presetCount: progress.presetCount,
          currentPresetName: progress.currentPreset.name,
          trackIndex: progress.trackIndex,
          trackCount: progress.trackCount,
          currentTrackName: progress.currentTrack.audioPath,
        );
      },
    );

    final failed = outcomes.where((o) => !o.result.success).toList();
    if (failed.isNotEmpty) {
      state = state.copyWith(
        phase: RenderPhase.error,
        message: failed.map((f) => '${f.preset.name}: ${f.result.errorMessage}').join('\n'),
      );
    } else {
      state = state.copyWith(phase: RenderPhase.done, outputPath: outputDir, percent: 1.0);
    }
  }

  void cancel() {
    _batchRenderService.cancel();
    _multiSongBatchService.cancel();
    _medleyRenderService.cancel();
    state = state.copyWith(phase: RenderPhase.cancelled);
  }

  Future<String> _defaultOutputDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, 'Spinclip'));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    return outDir.path;
  }

}

final renderJobProvider = NotifierProvider<RenderJobNotifier, RenderProgress>(RenderJobNotifier.new);

final previewServiceProvider = Provider<PreviewService>((ref) {
  final locator = FfmpegLocator();
  return PreviewService(locator: locator, audioProbe: AudioProbeService(locator));
});
