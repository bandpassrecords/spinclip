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
      settings: baseSettings(
        fullDuration: false,
        trimStart: 10,
        trimDuration: 20,
      ),
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
      VisualizerStyle.neonGlow: 'gblur',
      VisualizerStyle.cartoon: 'dilation',
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
      expect(
        filterComplex,
        contains(entry.value),
        reason: '${entry.key} should use ${entry.value}',
      );
    }
  });

  test('visualizer colour is applied to every audio channel', () {
    // A single colour only covers channel 1; showfreqs draws the rest white.
    final args = builder.buildArgs(
      settings: baseSettings(),
      width: 1920,
      height: 1080,
      audioDurationSeconds: 180,
      outputPath: 'out.mp4',
    );
    final filterComplex = args[args.indexOf('-filter_complex') + 1];
    expect(filterComplex, contains('colors=0x33CCFF|0x33CCFF|'));
  });

  String filterFor(RenderSettings settings) {
    final args = builder.buildArgs(
      settings: settings,
      width: 1920,
      height: 1080,
      audioDurationSeconds: 180,
      outputPath: 'out.mp4',
    );
    return args[args.indexOf('-filter_complex') + 1];
  }

  test('bar count renders one spectrum column per bar', () {
    final settings = baseSettings().copyWith(visualizerBarCount: 32);
    final filter = filterFor(settings);
    expect(filter, contains('showfreqs=s=32x'));
    expect(filter, contains('flags=neighbor'));
  });

  test('sensitivity zooms the spectrum around its middle', () {
    // bottomBand at 1080p is 238px tall; 2x draws it 476px and keeps the
    // centre slice.
    final neutral = filterFor(baseSettings().copyWith(visualizerBarCount: 0));
    expect(neutral, contains('crop=1920:238:0:0'));
    final zoomed = filterFor(
      baseSettings().copyWith(
        visualizerBarCount: 0,
        visualizerSensitivity: 2.0,
      ),
    );
    expect(zoomed, contains('showfreqs=s=1920x476'));
    expect(zoomed, contains('crop=1920:238:0:119'));
  });

  test('visualizer input is mixed to mono, except the stereo oscilloscope', () {
    expect(
      filterFor(baseSettings()),
      contains('[0:a]aformat=channel_layouts=mono,'),
    );
    expect(
      filterFor(baseSettings(style: VisualizerStyle.oscilloscope)),
      isNot(contains('channel_layouts=mono')),
    );
  });

  test('background uses a Gaussian blur scaled from blurRadius', () {
    expect(filterFor(baseSettings()), contains('gblur=sigma=16:steps=3[bg]'));
  });

  test('gradient draws white and multiplies by a two-color gradient', () {
    final filter = filterFor(
      baseSettings().copyWith(
        visualizerGradient: true,
        visualizerGradientColorHex: '0xFF3366',
      ),
    );
    expect(filter, contains('colors=0xFFFFFF|'));
    expect(filter, contains('c0=0x33CCFF:c1=0xFF3366'));
    expect(filter, contains('blend=all_mode=multiply'));
  });
}
