import 'package:flutter_test/flutter_test.dart';
import 'package:spinclip/models/render_settings.dart';
import 'package:spinclip/models/visualizer_placement.dart';
import 'package:spinclip/models/visualizer_style.dart';
import 'package:spinclip/services/filtergraph_builder.dart';

void main() {
  const builder = FiltergraphBuilder();

  RenderSettings baseSettings({
    bool fullDuration = true,
    double trimStart = 0,
    double? trimDuration,
    VisualizerPlacement placement = VisualizerPlacement.bottomBand,
    VisualizerStyle style = VisualizerStyle.bars,
  }) {
    return RenderSettings(
      imagePath: 'cover.jpg',
      audioPath: 'song.wav',
      placement: placement,
      style: style,
      fullDuration: fullDuration,
      trimStartSeconds: trimStart,
      trimDurationSeconds: trimDuration,
    );
  }

  test('full duration omits -ss/-t on the audio input', () {
    final args = builder.buildArgs(
      settings: baseSettings(),
      width: 1920,
      height: 1080,
      audioDurationSeconds: 180,
      outputPath: 'out.mp4',
    );

    expect(args, isNot(contains('-ss')));
    expect(args.where((a) => a == '-t'), isEmpty);
    expect(args, contains('cover.jpg'));
    expect(args, contains('song.wav'));
  });

  test('trimmed duration adds -ss/-t before the audio input', () {
    final args = builder.buildArgs(
      settings: baseSettings(fullDuration: false, trimStart: 10, trimDuration: 20),
      width: 1920,
      height: 1080,
      audioDurationSeconds: 180,
      outputPath: 'out.mp4',
    );

    final ssIndex = args.indexOf('-ss');
    final tIndex = args.indexOf('-t');
    final audioInputIndex = args.indexOf('song.wav');
    expect(ssIndex, greaterThanOrEqualTo(0));
    expect(args[ssIndex + 1], '10.000');
    expect(args[tIndex + 1], '20.000');
    expect(ssIndex, lessThan(audioInputIndex));
    expect(tIndex, lessThan(audioInputIndex));
  });

  test('fixedLoopSeconds overrides fullDuration (e.g. Spotify Canvas)', () {
    final args = builder.buildArgs(
      settings: baseSettings(fullDuration: true),
      width: 1080,
      height: 1920,
      audioDurationSeconds: 180,
      outputPath: 'out.mp4',
      fixedLoopSeconds: 8,
    );

    final tIndex = args.indexOf('-t');
    expect(tIndex, greaterThanOrEqualTo(0));
    expect(args[tIndex + 1], '8.000');
  });

  test('filter_complex references [outv] and maps audio+video', () {
    final args = builder.buildArgs(
      settings: baseSettings(),
      width: 1920,
      height: 1080,
      audioDurationSeconds: 180,
      outputPath: 'out.mp4',
    );

    final filterIndex = args.indexOf('-filter_complex');
    final filterComplex = args[filterIndex + 1];
    expect(filterComplex, contains('[outv]'));
    expect(filterComplex, contains('showfreqs'));
    expect(args, containsAllInOrder(['-map', '[outv]', '-map', '0:a']));
  });

  test('each visualizer style maps to the expected ffmpeg filter', () {
    final expectations = {
      VisualizerStyle.bars: 'showfreqs',
      VisualizerStyle.lineSpectrum: 'showfreqs',
      VisualizerStyle.fluidWave: 'showwaves',
      VisualizerStyle.oscilloscope: 'avectorscope',
    };

    for (final entry in expectations.entries) {
      final args = builder.buildArgs(
        settings: baseSettings(style: entry.key),
        width: 1920,
        height: 1080,
        audioDurationSeconds: 180,
        outputPath: 'out.mp4',
      );
      final filterComplex = args[args.indexOf('-filter_complex') + 1];
      expect(filterComplex, contains(entry.value), reason: '${entry.key} should use ${entry.value}');
    }
  });
}
