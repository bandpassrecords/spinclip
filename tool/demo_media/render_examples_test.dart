// Renders the example videos and stills the website shows, through the app's
// real FiltergraphBuilder and ffmpeg: what's on the site is what an export
// looks like, from the demo release tool/demo_media/make_demo_media.dart makes.
//
// Runs under `flutter test` (not `dart run`) because the models import
// Flutter's localizations, which need dart:ui. scripts/capture_screenshots.ps1
// runs it; on its own:
//
//   dart run tool/demo_media/make_demo_media.dart
//   flutter test tool/demo_media/render_examples_test.dart
//
// Writes resources/examples/: <name>.jpg stills and <name>.mp4 clips, small
// enough to serve from the website as they are.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spinclip/models/element_transform.dart';
import 'package:spinclip/models/render_settings.dart';
import 'package:spinclip/models/visualizer_placement.dart';
import 'package:spinclip/models/visualizer_style.dart';
import 'package:spinclip/services/filtergraph_builder.dart';
import 'package:spinclip/services/palette_extractor_service.dart';
import 'package:spinclip/services/qr_code_service.dart';

final _media = p.join('build', 'demo_media');
final _out = p.join('resources', 'examples');
final _work = p.join('build', 'demo_render');

String get _ffmpeg {
  final bundled = p.join('resources', 'tools', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg');
  return File(bundled).existsSync() ? bundled : 'ffmpeg';
}

String _cover(String name) => p.join(_media, '$name.png');
String _song(String title) => p.join(_media, '$title.wav');

/// Where in each song the examples are taken: past the intro, with the arp in.
const _from = 12.0;

class _Example {
  final String name;
  final RenderSettings settings;
  final int width;
  final int height;

  /// A clip of this many seconds is kept as `<name>.mp4`; otherwise only the
  /// still is.
  final double? clipSeconds;
  final String? qrAsset;

  const _Example(this.name, this.settings, this.width, this.height, {this.clipSeconds, this.qrAsset});
}

void main() {
  test('render website examples', () async {
    if (!File(_song('Low Orbit')).existsSync()) {
      fail('No demo media: run `dart run tool/demo_media/make_demo_media.dart` first.');
    }
    await Directory(_out).create(recursive: true);
    await Directory(_work).create(recursive: true);

    // The "Auto" colour the app offers for each cover.
    final palette = PaletteExtractorService();
    final auto = {
      for (final name in ['low_orbit', 'neon_tide', 'glass_hours'])
        name: await palette.extractAccentColorHex(_cover(name)),
    };

    RenderSettings release(String cover, String song, {String? color}) => RenderSettings(
          imagePath: _cover(cover),
          audioPath: _song(song),
          visualizerColorHex: color ?? auto[cover]!,
          fullDuration: false,
          trimStartSeconds: _from,
          trimDurationSeconds: 3,
          // AAC in MP4, so browsers play the clips.
          losslessAudio: false,
        );

    final lowOrbit = release('low_orbit', 'Low Orbit');
    final neonTide = release('neon_tide', 'Neon Tide');
    final glassHours = release('glass_hours', 'Glass Hours');

    final qr = await QrCodeService().generateQrPng(
      content: 'https://spinclip.bandpassrecords.com',
      sizePx: 360,
      captionText: 'Scan to listen',
    );

    final examples = <_Example>[
      // The homepage's hero: a whole clip, with sound.
      _Example('hero', lowOrbit, 1280, 720, clipSeconds: 10),

      // One release, every shape a platform asks for.
      _Example('platform-youtube', neonTide, 1280, 720),
      _Example('platform-square', neonTide, 720, 720),
      _Example('platform-portrait', neonTide, 720, 900),
      _Example('platform-vertical', neonTide.copyWith(placement: VisualizerPlacement.dualMirroredBottom), 540, 960,
          clipSeconds: 6),

      // Where the visualizer goes.
      for (final (placement, base) in [
        (VisualizerPlacement.bottomBand, lowOrbit),
        (VisualizerPlacement.sideBorder, glassHours),
        (VisualizerPlacement.dualMirroredBottom, neonTide),
        (VisualizerPlacement.fullFrameBorder, lowOrbit),
        (VisualizerPlacement.ascendingCorner, glassHours),
        (VisualizerPlacement.centeredBehindText, neonTide.copyWith(showText: true, textContent: 'Neon Tide')),
        (VisualizerPlacement.coverCenterDualBars, lowOrbit),
      ])
        _Example('placement-${placement.name}', base.copyWith(placement: placement), 960, 540),

      // How it draws the sound.
      for (final (style, base) in [
        (VisualizerStyle.bars, glassHours),
        (VisualizerStyle.lineSpectrum, lowOrbit),
        (VisualizerStyle.fluidWave, neonTide),
        (VisualizerStyle.oscilloscope, glassHours.copyWith(placement: VisualizerPlacement.centeredBehindText)),
        (VisualizerStyle.neonGlow, lowOrbit.copyWith(visualizerColorHex: '0xCC33FF')),
        (VisualizerStyle.cartoon, neonTide.copyWith(visualizerColorHex: '0xFFCC33')),
      ])
        _Example('style-${style.name}', base.copyWith(style: style), 960, 540),

      // A two-colour gradient, edge to tips.
      _Example(
        'gradient',
        glassHours.copyWith(
          style: VisualizerStyle.neonGlow,
          placement: VisualizerPlacement.dualMirroredBottom,
          visualizerBarCount: 64,
          visualizerColorHex: '0xFF3366',
          visualizerGradient: true,
          visualizerGradientColorHex: '0x33CCFF',
        ),
        960,
        540,
      ),

      // Logo, title and a QR code to the release, clear of the bars.
      _Example(
        'overlays',
        lowOrbit.copyWith(
          showLogo: true,
          logoImagePath: p.join(_media, 'logo.png'),
          logoTransform: const ElementTransform(dx: 0.92, dy: 0.13),
          showText: true,
          textContent: 'Halcyon Drift - Low Orbit',
          textTransform: const ElementTransform(dx: 0.5, dy: 0.8),
          showQrCode: true,
          qrCodeContent: 'https://spinclip.bandpassrecords.com',
          qrCaptionText: 'Scan to listen',
          qrTransform: const ElementTransform(dx: 0.08, dy: 0.16),
          coverSizeFraction: 0.6,
          coverTransform: const ElementTransform(dx: 0.5, dy: 0.42),
        ),
        1280,
        720,
        qrAsset: qr,
      ),
      _Example('vintage', glassHours.copyWith(vintageEffect: true), 960, 540),
    ];

    for (final example in examples) {
      final seconds = example.clipSeconds ?? 3;
      final settings = example.settings.copyWith(trimDurationSeconds: seconds);
      final raw = p.join(_work, '${example.name}.mp4');
      final args = const FiltergraphBuilder().buildArgs(
        settings: settings,
        width: example.width,
        height: example.height,
        audioDurationSeconds: 45,
        outputPath: raw,
        qrAssetPath: example.qrAsset,
      );
      await _run(args, example.name);

      // The still: late in the clip, so the visualizer has its history.
      await _run([
        '-y', '-ss', '${seconds - 0.6}', '-i', raw, //
        '-frames:v', '1', '-q:v', '3', p.join(_out, '${example.name}.jpg'),
      ], '${example.name} still');

      if (example.clipSeconds != null) {
        // Re-encoded small for the web, starting to play before it's all in.
        await _run([
          '-y', '-i', raw, //
          '-c:v', 'libx264', '-preset', 'slow', '-crf', '27', '-pix_fmt', 'yuv420p',
          '-c:a', 'aac', '-b:a', '128k', '-movflags', '+faststart',
          p.join(_out, '${example.name}.mp4'),
        ], '${example.name} web clip');
      }
      // ignore: avoid_print
      print('rendered ${example.name}');
    }
  }, timeout: Timeout.none);
}

Future<void> _run(List<String> args, String what) async {
  final result = await Process.run(_ffmpeg, ['-hide_banner', '-loglevel', 'error', ...args]);
  if (result.exitCode != 0) fail('$what failed:\n${result.stderr}');
}
