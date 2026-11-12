// Captures the screenshots the website shows, from the real app driving the
// real ffmpeg pipeline, on the demo release tool/demo_media/make_demo_media.dart
// makes — never someone else's artwork or music.
//
//   scripts/capture_screenshots.ps1
//
// Writes resources/screenshots/<name>.png: the 1280x800 window at 1.5x, so
// 1920x1200. The demo release is copied under C:\Users\Public\Music first,
// so the paths on screen are ordinary ones. Templates are kept in memory for the run, so the ones the
// pictures show never touch the templates saved on this machine. Not part of
// CI: it is a tool, run when the UI changes enough that the pictures no
// longer match it.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import 'package:spinclip/app/app.dart';
import 'package:spinclip/models/element_transform.dart';
import 'package:spinclip/models/release_mode.dart';
import 'package:spinclip/models/render_template.dart';
import 'package:spinclip/models/visualizer_placement.dart';
import 'package:spinclip/models/visualizer_style.dart';
import 'package:spinclip/services/palette_extractor_service.dart';
import 'package:spinclip/state/providers.dart';
import 'package:spinclip/ui/widgets/preview_panel.dart';

const _logical = Size(1280, 800);
const _pixelRatio = 1.5;

/// Where the demo release is copied to before the run, so the paths the app
/// shows are a musician's, not this repo's: the machine's shared Music
/// folder where there is one.
final String _media = () {
  const shared = r'C:\Users\Public\Music';
  return Platform.isWindows && Directory(shared).existsSync()
      ? p.join(shared, 'Halcyon Drift', 'Low Orbit EP')
      : p.join(Directory.systemTemp.path, 'Halcyon Drift', 'Low Orbit EP');
}();

/// Where the render the pictures show is written: next to the songs.
final String _outputDir = p.join(p.dirname(_media), 'Promo videos');

String _cover(String name) => p.join(_media, '$name.png');
String _song(String title) => p.join(_media, '$title.wav');

/// Copies build/demo_media (made by tool/demo_media/make_demo_media.dart)
/// to [_media], and clears the last run's render.
Future<void> _stageDemoMedia() async {
  final source = Directory(p.join('build', 'demo_media'));
  if (!source.existsSync()) {
    throw TestFailure('No demo media: run `dart run tool/demo_media/make_demo_media.dart` first.');
  }
  await Directory(_media).create(recursive: true);
  for (final file in source.listSync().whereType<File>()) {
    if (!RegExp(r'\.(png|wav)$').hasMatch(file.path)) continue;
    await file.copy(p.join(_media, p.basename(file.path)));
  }
  final output = Directory(_outputDir);
  if (output.existsSync()) await output.delete(recursive: true);
}

/// Templates for the run only: the built-in default plus a few a label might
/// keep, none of them read from or written to disk.
class _DemoTemplates extends TemplatesNotifier {
  @override
  List<RenderTemplate> build() => [
        ...builtInTemplates,
        templateFromDraft(
          const DraftSettings(
            style: VisualizerStyle.neonGlow,
            placement: VisualizerPlacement.dualMirroredBottom,
            visualizerColorHex: '0xCC33FF',
            selectedPresetIds: {'instagram_reels_stories', 'tiktok', 'spotify_canvas'},
          ),
          'Neon — vertical',
        ),
        templateFromDraft(
          const DraftSettings(
            style: VisualizerStyle.cartoon,
            visualizerColorHex: '0xFFCC33',
            vintageEffect: true,
          ),
          'Label house style',
        ),
      ];

  @override
  Future<void> save(RenderTemplate template) async {
    state = [...state.where((t) => t.name != template.name), template];
  }

  @override
  Future<void> delete(String name) async {
    state = state.where((t) => t.name != name || t.builtIn).toList();
  }
}

extension on WidgetTester {
  /// Lets animations and async loads finish without waiting on anything
  /// that never settles.
  Future<void> settle([int frames = 15]) async {
    for (var i = 0; i < frames; i++) {
      await pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> until(bool Function() done, String what, {Duration timeout = const Duration(seconds: 60)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (done()) return;
    }
    throw TestFailure('Timed out waiting for $what');
  }

  /// Waits for the live preview to finish rendering its frame through ffmpeg.
  Future<void> previewReady() async {
    final panel = find.byType(PreviewPanel);
    bool loaded() =>
        find.descendant(of: panel, matching: find.byType(Image)).evaluate().isNotEmpty &&
        find.descendant(of: panel, matching: find.byType(CircularProgressIndicator)).evaluate().isEmpty;
    // The panel debounces its regeneration: give it a moment to start.
    await settle(8);
    await until(loaded, 'the preview');
    await settle(10);
  }

  Future<void> tapText(String text) async {
    final target = find.text(text).hitTestable();
    await until(() => target.evaluate().isNotEmpty, '"$text"');
    await tap(target.first);
    await settle(6);
  }

  /// Steps Back/Next until the wizard shows [step].
  Future<void> goToStep(String step) async {
    final indicator = find.textContaining(RegExp(r'^Step \d+ of \d+: '));
    int current() {
      final text = (indicator.evaluate().first.widget as Text).data!;
      return int.parse(RegExp(r'^Step (\d+)').firstMatch(text)!.group(1)!);
    }

    while (current() > 1) {
      await tapText('Back');
    }
    for (var i = 0; i < 12; i++) {
      if (find.textContaining(': $step').evaluate().isNotEmpty) return;
      await tapText('Next');
    }
    throw TestFailure('Never reached the $step step');
  }

  Future<void> shot(String name) async {
    await settle();
    final view = binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    // The root layer already scales by the device pixel ratio, so its
    // bounds are in physical pixels.
    final image = await layer.toImage(Offset.zero & (view.size * _pixelRatio));
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(p.join('resources', 'screenshots', name));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
    debugPrint('SCREENSHOT $name');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshots', (tester) async {
    await _stageDemoMedia();
    tester.view.physicalSize = _logical * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    WidgetsApp.debugAllowBannerOverride = false;
    await windowManager.ensureInitialized();

    final container = ProviderContainer(
      overrides: [templatesProvider.overrideWith(_DemoTemplates.new)],
    );
    addTearDown(container.dispose);
    container.read(localeProvider.notifier).setLocale(const Locale('en'));
    final draft = container.read(draftSettingsProvider.notifier);

    final lowOrbitColor = await PaletteExtractorService().extractAccentColorHex(_cover('low_orbit'));

    // A single, filled in as someone would: cover, song, a colour from the
    // cover, and the platforms a release goes out to.
    draft
      ..setImagePath(_cover('low_orbit'))
      ..setAudioPath(_song('Low Orbit'))
      ..setColor(lowOrbitColor)
      ..setOutputDirectory(_outputDir);
    for (final id in ['instagram_feed', 'instagram_reels_stories', 'spotify_canvas']) {
      draft.togglePreset(id, true);
    }

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SpinclipApp()));
    await tester.previewReady();

    // One screen at a time: a screen that can't be reached is reported and
    // skipped, the rest still taken.
    final failed = <String>[];
    Future<void> screen(String name, Future<void> Function() steps) async {
      try {
        await steps();
      } catch (e) {
        failed.add('$name: ${'$e'.split('\n').first}');
        debugPrint('SKIPPED $name: $e');
      }
    }

    await screen('release type', () async {
      await tester.shot('release-type.png');
    });

    await screen('files', () async {
      await tester.goToStep('Files');
      await tester.settle(20);
      await tester.shot('files-single.png');
    });

    await screen('advanced', () async {
      await tester.goToStep('Release type');
      await tester.tapText('Advanced settings');
      await tester.goToStep('Visualizer');
      draft
        ..setStyle(VisualizerStyle.neonGlow)
        ..setPlacement(VisualizerPlacement.dualMirroredBottom);
      await tester.previewReady();
      await tester.shot('visualizer.png');
    });

    await screen('customize', () async {
      await tester.goToStep('Customize');
      // Every overlay at once, laid out clear of the bars along the bottom:
      // QR code and logo in the top corners, the title over the band.
      draft
        ..setPlacement(VisualizerPlacement.bottomBand)
        ..setCoverSizeFraction(0.6)
        ..setCoverTransform(const ElementTransform(dx: 0.5, dy: 0.44))
        ..setShowText(true)
        ..setTextContent('Halcyon Drift - Low Orbit')
        ..setTextTransform(const ElementTransform(dx: 0.5, dy: 0.8))
        ..setShowLogo(true)
        ..setLogoImagePath(p.join(_media, 'logo.png'))
        ..setLogoTransform(const ElementTransform(dx: 0.9, dy: 0.12))
        ..setShowQrCode(true)
        ..setQrCodeContent('https://spinclip.bandpassrecords.com')
        ..setQrCaptionText('Scan to listen')
        ..setQrTransform(const ElementTransform(dx: 0.1, dy: 0.14));
      await tester.previewReady();
      await tester.shot('customize.png');
      // The rest of the pictures show the plain look again.
      draft
        ..setShowText(false)
        ..setShowLogo(false)
        ..setShowQrCode(false)
        ..setCoverSizeFraction(0.82)
        ..setCoverTransform(ElementTransform.center)
        ..setPlacement(VisualizerPlacement.dualMirroredBottom);
    });

    await screen('duration', () async {
      await tester.goToStep('Duration');
      draft
        ..setFullDuration(false)
        ..setTrimStart(12)
        ..setTrimDuration(20);
      await tester.previewReady();
      await tester.settle(20);
      await tester.shot('duration.png');
    });

    await screen('platforms', () async {
      await tester.goToStep('Platforms');
      await tester.previewReady();
      await tester.shot('platforms.png');
    });

    await screen('output', () async {
      await tester.goToStep('Output & performance');
      await tester.shot('output.png');
    });

    await screen('review', () async {
      await tester.goToStep('Review & render');
      await tester.tapText('Save as template');
      await tester.enterText(find.byType(TextField).last, 'Low Orbit EP');
      await tester.settle();
      await tester.shot('review.png');
    });

    await screen('rendering', () async {
      await tester.tapText('Render');
      final bar = find.byType(LinearProgressIndicator);
      bool underway() => bar.evaluate().length > 1 &&
          bar.evaluate().map((e) => (e.widget as LinearProgressIndicator).value ?? 0).any((v) => v > 0 && v < 1 && v > 0.15);
      await tester.until(underway, 'the render to get going', timeout: const Duration(minutes: 3));
      await tester.shot('rendering.png');
      await tester.tapText('Cancel');
      await tester.settle(20);
    });

    // Batches: three songs, each with its own cover.
    final songs = [('Low Orbit', 'low_orbit'), ('Neon Tide', 'neon_tide'), ('Glass Hours', 'glass_hours')];

    await screen('multi-song', () async {
      await tester.goToStep('Release type');
      draft
        ..setReleaseMode(ReleaseMode.multiSong)
        ..setFullDuration(true);
      for (var i = container.read(draftSettingsProvider).tracks.length - 1; i >= 0; i--) {
        draft.removeTrackAt(i);
      }
      draft.addTracks([for (final (title, _) in songs) _song(title)]);
      for (final (i, (_, cover)) in songs.indexed) {
        final track = container.read(draftSettingsProvider).tracks[i];
        draft.updateTrackAt(i, track.copyWith(imagePath: _cover(cover)));
      }
      await tester.settle(10);
      await tester.shot('release-type-multi.png');
      await tester.goToStep('Files');
      await tester.previewReady();
      await tester.settle(20);
      await tester.shot('files-batch.png');
    });

    await screen('medley', () async {
      await tester.goToStep('Release type');
      draft.setReleaseMode(ReleaseMode.medley);
      for (var i = container.read(draftSettingsProvider).tracks.length - 1; i >= 0; i--) {
        draft.removeTrackAt(i);
      }
      draft.addTracks([for (final (title, _) in songs) _song(title)]);
      for (final (i, start) in [12.0, 16.0, 8.0].indexed) {
        final track = container.read(draftSettingsProvider).tracks[i];
        draft.updateTrackAt(i, track.copyWith(trimStartSeconds: start, trimDurationSeconds: 8));
      }
      await tester.goToStep('Files');
      await tester.previewReady();
      await tester.settle(20);
      await tester.shot('files-medley.png');
    });

    await screen('portuguese', () async {
      draft.setReleaseMode(ReleaseMode.single);
      container.read(localeProvider.notifier).setLocale(const Locale('pt'));
      await tester.settle(10);
      // The step names are in Portuguese now: Back until the first step.
      final back = find.byIcon(Icons.arrow_back).hitTestable();
      while (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        await tester.settle(6);
      }
      await tester.previewReady();
      await tester.shot('release-type-pt.png');
      container.read(localeProvider.notifier).setLocale(const Locale('en'));
    });

    if (failed.isNotEmpty) {
      fail('Screens not taken:\n  ${failed.join('\n  ')}');
    }
  }, timeout: Timeout.none);
}

