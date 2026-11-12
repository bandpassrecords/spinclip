// Makes the demo release the screenshots and the website's examples are
// taken with: three abstract cover images and three short synthesized songs,
// so no picture or video ever shows someone else's artwork or music.
//
//   dart run tool/demo_media/make_demo_media.dart [outDir]
//
// Writes to build/demo_media/ by default (ignored by git, rebuilt on demand):
//   low_orbit.png, neon_tide.png, glass_hours.png   1500x1500 covers
//   Low Orbit.wav, Neon Tide.wav, Glass Hours.wav   45 s, 44.1 kHz stereo
//   logo.png                                        a small transparent mark
//
// Deterministic: the same files every run, so the pictures only change when
// the app does. The songs are rendered by the bundled ffmpeg (aevalsrc).

// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

const _coverSize = 1500;

Future<void> main(List<String> args) async {
  final out = Directory(args.isNotEmpty ? args.first : p.join('build', 'demo_media'));
  await out.create(recursive: true);

  final covers = <String, img.Image Function()>{
    'low_orbit.png': _lowOrbit,
    'neon_tide.png': _neonTide,
    'glass_hours.png': _glassHours,
  };
  for (final entry in covers.entries) {
    final file = File(p.join(out.path, entry.key));
    await file.writeAsBytes(img.encodePng(entry.value()));
    print('cover  ${file.path}');
  }
  final logo = File(p.join(out.path, 'logo.png'));
  await logo.writeAsBytes(img.encodePng(_logo()));
  print('logo   ${logo.path}');

  final ffmpeg = _ffmpeg();
  for (final song in _songs) {
    final file = p.join(out.path, '${song.title}.wav');
    final result = await Process.run(ffmpeg, [
      '-y', '-hide_banner', '-loglevel', 'error',
      '-f', 'lavfi',
      '-i', "aevalsrc=exprs='${song.expression()}':s=44100:d=${song.seconds}",
      '-af', 'afade=t=in:d=1.5,afade=t=out:st=${song.seconds - 3}:d=3,alimiter=limit=0.9',
      '-c:a', 'pcm_s16le',
      '-metadata', 'title=${song.title}',
      '-metadata', 'artist=Halcyon Drift',
      '-metadata', 'album=Low Orbit EP',
      file,
    ]);
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      exit(result.exitCode);
    }
    print('song   $file');
  }
}

String _ffmpeg() {
  final bundled = p.join('resources', 'tools', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg');
  return File(bundled).existsSync() ? bundled : 'ffmpeg';
}

// ---------------------------------------------------------------------------
// Songs: kick, off-beat hats, a pumping bass and pad on a four-chord loop, and
// a sixteenth-note arpeggio that comes in after the first two bars — enough
// movement across the spectrum that every visualizer style has something to
// draw.

class _Song {
  final String title;
  final double bpm;

  /// Bass roots of the four-chord loop, in Hz (one chord per bar).
  final List<double> roots;

  /// Whether each chord is minor (else major).
  final List<bool> minor;

  /// The arpeggio's eight steps, in semitones above the chord's root.
  final List<int> arp;
  final int seconds;

  const _Song(this.title, this.bpm, this.roots, this.minor, this.arp) : seconds = 45;

  String expression() {
    final beat = 60 / bpm;
    final bar = beat * 4;
    final b = 'mod(t,$beat)';
    // The chord of the current bar, as a nested if over 0..3.
    String perChord(List<String> values) {
      final i = 'floor(mod(t,${bar * 4})/$bar)';
      return 'if(eq($i,0),${values[0]},if(eq($i,1),${values[1]},if(eq($i,2),${values[2]},${values[3]})))';
    }

    final root = perChord([for (final r in roots) '$r']);
    final third = perChord([for (final m in minor) m ? '1.1892' : '1.2599']);
    final step = 'mod(floor(t/${beat / 4}),8)';
    String arpStep() {
      var expr = '${arp.last}';
      for (var i = arp.length - 2; i >= 0; i--) {
        expr = 'if(eq($step,$i),${arp[i]},$expr)';
      }
      return expr;
    }

    // Each channel a little different (noise seed, pad detune, arp pan), so
    // the stereo oscilloscope draws a figure rather than a diagonal line.
    String channel(int c) {
      final detune = c == 0 ? 1.0 : 1.004;
      final pan = c == 0 ? '(1+0.5*sin(t*1.3))' : '(1-0.5*sin(t*1.3))';
      final pump = '(1-0.8*exp(-9*$b))';
      final kick = '0.9*sin(2*PI*(45*$b+3.3*(1-exp(-30*$b))))*exp(-7*$b)';
      // Closed hats on the off-beat, an open one at the end of every bar.
      final hat = '(2*random($c)-1)*(0.2*exp(-35*mod(t+${beat / 2},$beat))'
          '+0.12*gte(mod(t,$bar),${bar - beat / 2})*exp(-6*mod(t+${beat / 2},$beat)))';
      final bass = '0.32*$pump*(sin(2*PI*$root*t)+0.3*sin(4*PI*$root*t))';
      final pad = '0.06*$pump*(sin(8*PI*$root*$detune*t)+sin(8*PI*$root*$third*$detune*t)'
          '+sin(8*PI*$root*1.4983*$detune*t)+0.5*sin(16*PI*$root*1.4983*$detune*t))';
      // A bright, saw-like arp: six harmonics, each quieter than the last.
      final arpFreq = '16*$root*pow(2,${arpStep()}/12)';
      final harmonics = [for (var n = 1; n <= 6; n++) '${(1 / n).toStringAsFixed(3)}*sin(2*PI*$n*$arpFreq*t)'].join('+');
      final arpVoice = '0.07*$pan*gte(t,${bar * 2})*exp(-12*mod(t,${beat / 4}))*($harmonics)';
      // A quiet bed of air over everything, breathing with the kick.
      final air = '0.006*$pump*(2*random(${c + 2})-1)';
      return '0.55*($kick+$hat+$bass+$pad+$arpVoice+$air)';
    }

    return '${channel(0)}|${channel(1)}';
  }
}

const _songs = [
  _Song('Low Orbit', 120, [55.0, 43.65, 49.0, 41.2], [true, false, false, false], [0, 3, 7, 12, 7, 3, 10, 7]),
  _Song('Neon Tide', 124, [49.0, 41.2, 55.0, 46.25], [false, true, true, false], [0, 4, 7, 11, 14, 11, 7, 4]),
  _Song('Glass Hours', 100, [36.71, 46.25, 41.2, 55.0], [true, false, true, false], [0, 7, 12, 15, 12, 7, 3, 7]),
];

// ---------------------------------------------------------------------------
// Covers: plain geometry and gradients, drawn pixel by pixel.

typedef _Rgb = (double, double, double);

_Rgb _mix(_Rgb a, _Rgb b, double t) =>
    (a.$1 + (b.$1 - a.$1) * t, a.$2 + (b.$2 - a.$2) * t, a.$3 + (b.$3 - a.$3) * t);

double _smooth(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

img.Image _paint(_Rgb Function(double x, double y) shade, {int seed = 1}) {
  final image = img.Image(width: _coverSize, height: _coverSize);
  final random = math.Random(seed);
  for (var py = 0; py < _coverSize; py++) {
    for (var px = 0; px < _coverSize; px++) {
      final c = shade(px / _coverSize, py / _coverSize);
      // Light film grain, so flat gradients don't band.
      final grain = (random.nextDouble() - 0.5) * 10;
      image.setPixelRgb(
        px,
        py,
        (c.$1 + grain).clamp(0, 255).round(),
        (c.$2 + grain).clamp(0, 255).round(),
        (c.$3 + grain).clamp(0, 255).round(),
      );
    }
  }
  return image;
}

/// A striped sun setting into layered waves under a violet sky.
img.Image _lowOrbit() {
  const skyTop = (24.0, 14.0, 58.0);
  const skyLow = (214.0, 62.0, 112.0);
  const sunTop = (255.0, 214.0, 92.0);
  const sunLow = (255.0, 96.0, 64.0);
  const sea = (18.0, 10.0, 44.0);
  return _paint((x, y) {
    var c = _mix(skyTop, skyLow, _smooth(0.0, 0.62, y));
    // The sun, cut by bands that widen towards the horizon.
    final d = math.sqrt(math.pow(x - 0.5, 2) + math.pow(y - 0.5, 2));
    if (d < 0.27) {
      final band = y > 0.46 && math.sin((y - 0.46) * 160) > 0.9 - (y - 0.46) * 9;
      if (!band) {
        final edge = 1 - _smooth(0.265, 0.27, d);
        c = _mix(c, _mix(sunTop, sunLow, _smooth(0.23, 0.77, y)), edge);
      }
    }
    // Waves below the horizon, each a little darker than the one behind.
    for (var i = 0; i < 5; i++) {
      final base = 0.66 + i * 0.075;
      final wave = base + 0.018 * math.sin(x * math.pi * (3 + i) + i * 1.7);
      if (y > wave) c = _mix(sea, skyLow, 0.38 - i * 0.08);
    }
    return c;
  }, seed: 11);
}

/// Concentric rings rippling out from low on the frame, teal into ink.
img.Image _neonTide() {
  const ink = (6.0, 18.0, 32.0);
  const teal = (22.0, 214.0, 196.0);
  const lime = (190.0, 255.0, 120.0);
  return _paint((x, y) {
    final d = math.sqrt(math.pow(x - 0.5, 2) + math.pow((y - 0.72) * 1.15, 2));
    final ring = 0.5 + 0.5 * math.cos(d * 70 - math.sin(x * 9) * 0.6);
    final fall = 1 - _smooth(0.0, 0.9, d);
    var c = _mix(ink, _mix(teal, lime, _smooth(0.0, 0.35, 0.35 - d)), ring * fall * 0.9);
    // A bright disc at the source.
    c = _mix(c, lime, 1 - _smooth(0.05, 0.065, d));
    return c;
  }, seed: 23);
}

/// A grid of glass discs catching an amber light, over plum.
img.Image _glassHours() {
  const plum = (40.0, 16.0, 46.0);
  const amber = (255.0, 170.0, 64.0);
  const rose = (240.0, 110.0, 150.0);
  return _paint((x, y) {
    var c = _mix(plum, (70.0, 24.0, 64.0), y);
    const cells = 6;
    final cx = (x * cells).floor(), cy = (y * cells).floor();
    final fx = x * cells - cx - 0.5, fy = y * cells - cy - 0.5;
    final d = math.sqrt(fx * fx + fy * fy);
    // Bigger discs towards the light, top right.
    final light = 1 - math.sqrt(math.pow(1 - (cx + 0.5) / cells, 2) + math.pow((cy + 0.5) / cells, 2)) / 1.4;
    final radius = 0.12 + 0.3 * light;
    if (d < radius) {
      final edge = 1 - _smooth(radius - 0.01, radius, d);
      final glow = _mix(rose, amber, light);
      final highlight = _smooth(0.5, 0.0, math.sqrt(math.pow(fx + 0.12, 2) + math.pow(fy + 0.12, 2)) / radius);
      c = _mix(c, _mix(glow, (255.0, 244.0, 220.0), highlight * 0.6), edge * (0.55 + 0.45 * light));
    }
    return c;
  }, seed: 37);
}

/// A small white disc-and-wave mark on transparency, for the logo overlay.
img.Image _logo() {
  const size = 400;
  final image = img.Image(width: size, height: size, numChannels: 4);
  for (var py = 0; py < size; py++) {
    for (var px = 0; px < size; px++) {
      final x = px / size - 0.5, y = py / size - 0.5;
      final d = math.sqrt(x * x + y * y);
      var a = 1 - _smooth(0.44, 0.45, d);
      a -= 1 - _smooth(0.37, 0.38, d);
      final wave = 0.06 * math.sin(x * math.pi * 6);
      if ((y - wave).abs() < 0.035 && d < 0.38) a = 1;
      image.setPixelRgba(px, py, 255, 255, 255, (a.clamp(0.0, 1.0) * 255).round());
    }
  }
  return image;
}
