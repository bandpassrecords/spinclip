// ignore_for_file: avoid_print
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:spinclip/models/platform_preset.dart';
import 'package:spinclip/models/qr_caption_position.dart';
import 'package:spinclip/models/render_settings.dart';
import 'package:spinclip/models/track.dart';
import 'package:spinclip/models/visualizer_placement.dart';
import 'package:spinclip/models/visualizer_style.dart';
import 'package:spinclip/services/audio_probe_service.dart';
import 'package:spinclip/services/batch_render_service.dart';
import 'package:spinclip/services/concat_service.dart';
import 'package:spinclip/services/ffmpeg_locator.dart';
import 'package:spinclip/services/medley_render_service.dart';
import 'package:spinclip/services/multi_song_batch_service.dart';
import 'package:spinclip/services/qr_code_service.dart';
import 'package:spinclip/services/video_render_service.dart';

const _modeSingle = 'single';
const _modeMultiSong = 'multi-song';
const _modeMedley = 'medley';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('image', help: 'Path to the default/shared cover image', mandatory: true)
    ..addOption('audio', help: 'Path to the audio file (single mode only)')
    ..addMultiOption(
      'track',
      help: 'A song for multi-song/medley mode: "audioPath[:start[:duration]]". '
          'Repeat --track once per song, in playback order for medley mode.',
    )
    ..addOption(
      'mode',
      help: 'single: one song -> one output per preset. '
          'multi-song: N songs -> N independent outputs per preset. '
          'medley: N songs -> one combined video per preset, each song contributing a trimmed excerpt.',
      allowed: [_modeSingle, _modeMultiSong, _modeMedley],
      defaultsTo: _modeSingle,
    )
    ..addOption('output-dir', help: 'Directory to write output video(s) into', defaultsTo: '.')
    ..addMultiOption(
      'presets',
      help: 'Platform presets to render, comma-separated',
      allowed: PlatformPreset.all.map((p) => p.id).toList(),
      defaultsTo: [PlatformPreset.youtube.id],
    )
    ..addOption(
      'placement',
      help: 'Visualizer placement',
      allowed: VisualizerPlacement.values.map((e) => e.name).toList(),
      defaultsTo: VisualizerPlacement.bottomBand.name,
    )
    ..addOption(
      'style',
      help: 'Visualizer style',
      allowed: VisualizerStyle.values.map((e) => e.name).toList(),
      defaultsTo: VisualizerStyle.bars.name,
    )
    ..addOption('color', help: 'Visualizer color (0xRRGGBB)', defaultsTo: '0x33CCFF')
    ..addOption('blur', help: 'Background blur radius', defaultsTo: '20')
    ..addFlag(
      'vintage',
      help: 'Mild old-school aging look on the whole frame: warm sepia tint, slight vignette, light film grain.',
      defaultsTo: false,
    )
    ..addOption(
      'cover-size',
      help: 'Sharp cover size as a fraction (0.2-1.0) of the shorter frame side',
      defaultsTo: '0.82',
    )
    ..addFlag('logo', help: 'Enable logo overlay', defaultsTo: false)
    ..addOption('logo-path', help: 'Path to logo image (required if --logo)')
    ..addFlag('text', help: 'Enable text overlay', defaultsTo: false)
    ..addOption('text-content', help: 'Text overlay content', defaultsTo: '')
    ..addOption('qr-content', help: 'Enable a QR code overlay encoding this text/URL')
    ..addOption('qr-caption', help: 'Optional caption baked above/below the QR code (e.g. "Scan to listen")', defaultsTo: '')
    ..addOption(
      'qr-caption-position',
      help: 'Where the QR caption is baked relative to the code',
      allowed: QrCaptionPosition.values.map((e) => e.name).toList(),
      defaultsTo: QrCaptionPosition.below.name,
    )
    ..addOption('fade-in', help: 'Fade-in duration in seconds (video+audio)', defaultsTo: '0')
    ..addOption('fade-out', help: 'Fade-out duration in seconds (video+audio)', defaultsTo: '0')
    ..addOption(
      'smoothness',
      help: 'Visualizer smoothing (0.0 choppy - 1.0 very smooth)',
      defaultsTo: '0.5',
    )
    ..addFlag(
      'full-duration',
      help: 'Single/multi-song mode: render the full track (default). '
          'Ignored in medley mode, where each --track excerpt is always trimmed.',
      defaultsTo: true,
    )
    ..addOption('start', help: 'Single mode trim start in seconds (used when --no-full-duration)', defaultsTo: '0')
    ..addOption('duration', help: 'Single mode trim duration in seconds (used when --no-full-duration)')
    ..addOption('snippet-duration', help: 'Default excerpt length in seconds for medley tracks that omit :duration', defaultsTo: '8')
    ..addFlag(
      'hw-accel',
      help: 'Use a GPU encoder (NVENC/Quick Sync/AMF/etc.) if available, falling back to software libx264 on failure. Default: on.',
      defaultsTo: true,
    )
    ..addFlag(
      'lossless-audio',
      help: 'Mux uncompressed PCM audio instead of AAC (writes .mov instead of .mp4). Default: on. '
          'Spotify Canvas always uses AAC/MP4 regardless, since that platform requires it.',
      defaultsTo: true,
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

  late final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (args['help'] as bool) {
    print(parser.usage);
    return;
  }

  final imagePath = args['image'] as String;
  final outputDir = args['output-dir'] as String;
  final mode = args['mode'] as String;

  final presetIds = (args['presets'] as List<String>).toSet();
  final presets = PlatformPreset.all.where((p) => presetIds.contains(p.id)).toList();
  if (presets.isEmpty) {
    stderr.writeln('No valid presets selected.');
    exitCode = 64;
    return;
  }

  final templateSettings = RenderSettings(
    imagePath: imagePath,
    audioPath: '', // overridden per track in multi-song/medley mode; unused placeholder
    placement: VisualizerPlacement.values.byName(args['placement'] as String),
    style: VisualizerStyle.values.byName(args['style'] as String),
    visualizerColorHex: args['color'] as String,
    blurRadius: double.parse(args['blur'] as String),
    coverSizeFraction: double.parse(args['cover-size'] as String),
    showLogo: args['logo'] as bool,
    logoImagePath: args['logo-path'] as String?,
    showText: args['text'] as bool,
    textContent: args['text-content'] as String,
    showQrCode: args['qr-content'] != null,
    qrCodeContent: args['qr-content'] as String? ?? '',
    qrCaptionText: args['qr-caption'] as String? ?? '',
    qrCaptionPosition: QrCaptionPosition.values.byName(args['qr-caption-position'] as String),
    fadeInSeconds: double.parse(args['fade-in'] as String),
    fadeOutSeconds: double.parse(args['fade-out'] as String),
    visualizerSmoothness: double.parse(args['smoothness'] as String),
    losslessAudio: args['lossless-audio'] as bool,
    vintageEffect: args['vintage'] as bool,
  );

  final useHardwareAcceleration = args['hw-accel'] as bool;

  final locator = FfmpegLocator();
  final videoRenderService = VideoRenderService(locator: locator, audioProbe: AudioProbeService(locator));

  String? qrAssetPath;
  if (templateSettings.showQrCode && templateSettings.qrCodeContent.isNotEmpty) {
    qrAssetPath = await QrCodeService().generateQrPng(
      content: templateSettings.qrCodeContent,
      sizePx: 512,
      captionText: args['qr-caption'] as String? ?? '',
      captionPosition: templateSettings.qrCaptionPosition,
    );
  }

  int exitStatus;
  switch (mode) {
    case _modeSingle:
      exitStatus = await _runSingle(
        args: args,
        templateSettings: templateSettings,
        presets: presets,
        outputDir: outputDir,
        qrAssetPath: qrAssetPath,
        useHardwareAcceleration: useHardwareAcceleration,
        videoRenderService: videoRenderService,
      );
      break;
    case _modeMultiSong:
      exitStatus = await _runMultiSong(
        args: args,
        templateSettings: templateSettings,
        defaultImagePath: imagePath,
        presets: presets,
        outputDir: outputDir,
        qrAssetPath: qrAssetPath,
        useHardwareAcceleration: useHardwareAcceleration,
        videoRenderService: videoRenderService,
      );
      break;
    case _modeMedley:
      exitStatus = await _runMedley(
        args: args,
        templateSettings: templateSettings,
        defaultImagePath: imagePath,
        presets: presets,
        outputDir: outputDir,
        qrAssetPath: qrAssetPath,
        useHardwareAcceleration: useHardwareAcceleration,
        videoRenderService: videoRenderService,
        locator: locator,
      );
      break;
    default:
      exitStatus = 64;
  }

  exitCode = exitStatus;
}

Future<int> _runSingle({
  required ArgResults args,
  required RenderSettings templateSettings,
  required List<PlatformPreset> presets,
  required String outputDir,
  String? qrAssetPath,
  required bool useHardwareAcceleration,
  required VideoRenderService videoRenderService,
}) async {
  final audioPath = args['audio'] as String?;
  if (audioPath == null) {
    stderr.writeln('--audio is required in single mode.');
    return 64;
  }

  final settings = templateSettings.copyWith(
    audioPath: audioPath,
    fullDuration: args['full-duration'] as bool,
    trimStartSeconds: double.parse(args['start'] as String),
    trimDurationSeconds: args['duration'] != null ? double.parse(args['duration'] as String) : null,
  );

  final batchService = BatchRenderService(videoRenderService);
  print('Rendering ${presets.length} preset(s) to $outputDir ...');

  final outcomes = await batchService.renderAll(
    settings: settings,
    presets: presets,
    outputDirectory: outputDir,
    qrAssetPath: qrAssetPath,
    useHardwareAcceleration: useHardwareAcceleration,
    onProgress: (progress) {
      final pct = (progress.percentWithinPreset * 100).toStringAsFixed(0);
      stdout.write('\r[${progress.presetIndex + 1}/${progress.presetCount}] ${progress.currentPreset.name}: $pct%   ');
    },
  );
  print('');

  var failures = 0;
  for (final outcome in outcomes) {
    if (outcome.result.success) {
      print('OK   ${outcome.preset.name} -> ${outcome.result.outputPath}');
    } else {
      failures++;
      print('FAIL ${outcome.preset.name}: ${outcome.result.errorMessage}');
    }
  }
  return failures == 0 ? 0 : 1;
}

Future<int> _runMultiSong({
  required ArgResults args,
  required RenderSettings templateSettings,
  required String defaultImagePath,
  required List<PlatformPreset> presets,
  required String outputDir,
  String? qrAssetPath,
  required bool useHardwareAcceleration,
  required VideoRenderService videoRenderService,
}) async {
  final tracks = _parseTracks(args['track'] as List<String>, defaultDurationSeconds: null, fullDurationDefault: true);
  if (tracks == null) return 64;
  if (tracks.isEmpty) {
    stderr.writeln('At least one --track is required in multi-song mode.');
    return 64;
  }

  final service = MultiSongBatchService(videoRenderService);
  print('Rendering ${tracks.length} song(s) x ${presets.length} preset(s) to $outputDir ...');

  final outcomes = await service.renderAll(
    templateSettings: templateSettings,
    tracks: tracks,
    defaultImagePath: defaultImagePath,
    presets: presets,
    outputDirectory: outputDir,
    qrAssetPath: qrAssetPath,
    useHardwareAcceleration: useHardwareAcceleration,
    onProgress: (progress) {
      final pct = (progress.percentWithinJob * 100).toStringAsFixed(0);
      stdout.write(
        '\r[song ${progress.trackIndex + 1}/${progress.trackCount}] '
        '[preset ${progress.presetIndex + 1}/${progress.presetCount}] '
        '${progress.currentPreset.name}: $pct%   ',
      );
    },
  );
  print('');

  var failures = 0;
  for (final outcome in outcomes) {
    final name = p.basenameWithoutExtension(outcome.track.audioPath);
    if (outcome.result.success) {
      print('OK   $name / ${outcome.preset.name} -> ${outcome.result.outputPath}');
    } else {
      failures++;
      print('FAIL $name / ${outcome.preset.name}: ${outcome.result.errorMessage}');
    }
  }
  return failures == 0 ? 0 : 1;
}

Future<int> _runMedley({
  required ArgResults args,
  required RenderSettings templateSettings,
  required String defaultImagePath,
  required List<PlatformPreset> presets,
  required String outputDir,
  String? qrAssetPath,
  required bool useHardwareAcceleration,
  required VideoRenderService videoRenderService,
  required FfmpegLocator locator,
}) async {
  final snippetDuration = double.parse(args['snippet-duration'] as String);
  final tracks = _parseTracks(args['track'] as List<String>, defaultDurationSeconds: snippetDuration, fullDurationDefault: false);
  if (tracks == null) return 64;
  if (tracks.length < 2) {
    stderr.writeln('At least two --track entries are required in medley mode.');
    return 64;
  }

  final service = MedleyRenderService(videoRenderService, ConcatService(locator));
  print('Rendering a ${tracks.length}-track medley for ${presets.length} preset(s) to $outputDir ...');

  final outcomes = await service.renderMedley(
    templateSettings: templateSettings,
    tracks: tracks,
    defaultImagePath: defaultImagePath,
    presets: presets,
    outputDirectory: outputDir,
    qrAssetPath: qrAssetPath,
    useHardwareAcceleration: useHardwareAcceleration,
    onProgress: (progress) {
      final pct = (progress.percentWithinTrack * 100).toStringAsFixed(0);
      stdout.write(
        '\r[preset ${progress.presetIndex + 1}/${progress.presetCount}] ${progress.currentPreset.name} '
        '[track ${progress.trackIndex + 1}/${progress.trackCount}]: $pct%   ',
      );
    },
  );
  print('');

  var failures = 0;
  for (final outcome in outcomes) {
    if (outcome.result.success) {
      print('OK   ${outcome.preset.name} -> ${outcome.result.outputPath}');
    } else {
      failures++;
      print('FAIL ${outcome.preset.name}: ${outcome.result.errorMessage}');
    }
  }
  return failures == 0 ? 0 : 1;
}

/// Parses repeated --track values of the form "audioPath[:start[:duration]]".
/// Returns null (after printing an error) on a malformed entry.
List<Track>? _parseTracks(
  List<String> raw, {
  required double? defaultDurationSeconds,
  required bool fullDurationDefault,
}) {
  final tracks = <Track>[];
  for (final entry in raw) {
    final parts = entry.split(':');
    if (parts.isEmpty || parts.first.isEmpty) {
      stderr.writeln('Invalid --track value: "$entry"');
      return null;
    }
    final audioPath = parts[0];
    final start = parts.length > 1 && parts[1].isNotEmpty ? double.tryParse(parts[1]) : 0.0;
    final duration = parts.length > 2 && parts[2].isNotEmpty ? double.tryParse(parts[2]) : defaultDurationSeconds;
    if (start == null) {
      stderr.writeln('Invalid start time in --track value: "$entry"');
      return null;
    }
    tracks.add(Track(
      audioPath: audioPath,
      fullDuration: fullDurationDefault && duration == null,
      trimStartSeconds: start,
      trimDurationSeconds: duration,
    ));
  }
  return tracks;
}
