// Renders a preview gallery: one short clip per variant listed in a gallery
// JSON file, through the app's real FiltergraphBuilder + ffmpeg, so what's
// shown is what an export would look like.
//
// Runs under `flutter test` (not `dart run`) because the models import
// Flutter's localizations, which need dart:ui:
//
//   flutter test tool/preview/gallery_test.dart
//   flutter test tool/preview/gallery_test.dart --dart-define=GALLERY=tool/preview/my_round.json
//
// Sample audio and cover live in tool/preview/samples/ (gitignored). Output
// goes to tool/preview/out/<gallery name>/: one .mp4 + poster .jpg per
// variant, a manifest.json, and an index.html that plays them side by side.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spinclip/models/render_settings.dart';
import 'package:spinclip/models/visualizer_placement.dart';
import 'package:spinclip/models/visualizer_style.dart';
import 'package:spinclip/services/filtergraph_builder.dart';

const _defaultGallery = 'tool/preview/gallery.json';

void main() {
  test('render preview gallery', () async {
    const galleryPath = String.fromEnvironment(
      'GALLERY',
      defaultValue: _defaultGallery,
    );
    final config =
        jsonDecode(File(galleryPath).readAsStringSync())
            as Map<String, dynamic>;
    final name = config['name'] as String;
    final audio = config['audio'] as String;
    final cover = config['cover'] as String;
    final clipStart = (config['clipStart'] as num).toDouble();
    final clipSeconds = (config['clipSeconds'] as num).toDouble();
    final width = config['width'] as int;
    final height = config['height'] as int;
    final base = (config['base'] as Map<String, dynamic>?) ?? {};

    final outDir = Directory('tool/preview/out/$name')
      ..createSync(recursive: true);
    final manifest = <Map<String, dynamic>>[];

    final variants = (config['variants'] as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < variants.length; i++) {
      final variant = variants[i];
      final id = (i + 1).toString().padLeft(2, '0');
      final overrides = {...base, ...?variant['settings'] as Map?};
      final settings = _settingsFrom(overrides, audio: audio, cover: cover)
          .copyWith(
            fullDuration: false,
            trimStartSeconds: clipStart,
            trimDurationSeconds: clipSeconds,
            // AAC/MP4 so browsers can play the clip.
            losslessAudio: false,
          );
      final clip = '${outDir.path}/$id.mp4';
      final args = const FiltergraphBuilder().buildArgs(
        settings: settings,
        width: width,
        height: height,
        audioDurationSeconds: clipStart + clipSeconds,
        outputPath: clip,
      );
      final result = await Process.run('ffmpeg', ['-v', 'error', ...args]);
      if (result.exitCode != 0) {
        fail('Variant $id (${variant['title']}) failed:\n${result.stderr}');
      }
      await Process.run('ffmpeg', [
        '-y', '-v', 'error', '-ss', '${clipSeconds / 2}', '-i', clip, //
        '-frames:v', '1', '-q:v', '4', '${outDir.path}/$id.jpg',
      ]);
      manifest.add({
        'id': id,
        'title': variant['title'],
        'note': variant['note'] ?? '',
        'settings': overrides,
        'clip': '$id.mp4',
        'poster': '$id.jpg',
      });
      // ignore: avoid_print
      print('rendered $id ${variant['title']}');
    }

    File('${outDir.path}/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'name': name,
        'title': config['title'] ?? name,
        'intro': config['intro'] ?? '',
        'variants': manifest,
      }),
    );
    final template = File(
      'tool/preview/gallery_template.html',
    ).readAsStringSync();
    File('${outDir.path}/index.html').writeAsStringSync(
      template
          .replaceAll('__GALLERY_TITLE__', _htmlEscape(config['title'] ?? name))
          .replaceAll(
            '__GALLERY_DATA__',
            jsonEncode({
              'name': name,
              'title': config['title'] ?? name,
              'intro': config['intro'] ?? '',
              'variants': manifest,
            }).replaceAll('</', '<\\/'),
          ),
    );
  }, timeout: Timeout.none);
}

String _htmlEscape(Object s) => s
    .toString()
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// Maps the short keys used in gallery JSON onto RenderSettings.
RenderSettings _settingsFrom(
  Map<dynamic, dynamic> s, {
  required String audio,
  required String cover,
}) {
  T? get<T>(String key) => s[key] as T?;
  double? num_(String key) => (s[key] as num?)?.toDouble();
  const d = RenderSettings(imagePath: '', audioPath: '');
  return RenderSettings(
    imagePath: cover,
    audioPath: audio,
    style: get<String>('style') != null
        ? VisualizerStyle.values.byName(get<String>('style')!)
        : d.style,
    placement: get<String>('placement') != null
        ? VisualizerPlacement.values.byName(get<String>('placement')!)
        : d.placement,
    visualizerColorHex: get<String>('color') ?? d.visualizerColorHex,
    visualizerGradient: get<String>('gradientColor') != null,
    visualizerGradientColorHex:
        get<String>('gradientColor') ?? d.visualizerGradientColorHex,
    visualizerBarCount: get<int>('barCount') ?? d.visualizerBarCount,
    visualizerSensitivity: num_('sensitivity') ?? d.visualizerSensitivity,
    visualizerSmoothness: num_('smoothness') ?? d.visualizerSmoothness,
    blurRadius: num_('blur') ?? d.blurRadius,
    coverSizeFraction: num_('coverSize') ?? d.coverSizeFraction,
    showCover: get<bool>('showCover') ?? d.showCover,
    vintageEffect: get<bool>('vintage') ?? d.vintageEffect,
  );
}
