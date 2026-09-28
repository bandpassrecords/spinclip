import 'dart:math' as math;

import '../models/element_transform.dart';
import '../models/render_settings.dart';
import '../models/visualizer_placement.dart';
import '../models/visualizer_style.dart';

/// Pure builder: (RenderSettings, target size, probed audio duration) ->
/// a full ffmpeg argument list. No I/O, no process spawning - fully
/// unit-testable and shared by both the CLI and the GUI.
class FiltergraphBuilder {
  const FiltergraphBuilder();

  List<String> buildArgs({
    required RenderSettings settings,
    required int width,
    required int height,
    required double audioDurationSeconds,
    required String outputPath,
    String? qrAssetPath,
    double? fixedLoopSeconds,
    String videoCodec = 'libx264',
  }) {
    final _Trim trim = _resolveTrim(
      settings,
      audioDurationSeconds,
      fixedLoopSeconds,
    );

    final args = <String>['-y'];

    if (trim.applyTrim) {
      args.addAll([
        '-ss',
        trim.start.toStringAsFixed(3),
        '-t',
        trim.duration.toStringAsFixed(3),
      ]);
    }
    args.addAll(['-i', settings.audioPath]); // input 0: audio

    args.addAll([
      '-loop',
      '1',
      '-i',
      settings.imagePath,
    ]); // input 1: cover image

    int nextIndex = 2;
    int? logoIndex;
    if (settings.showLogo && settings.logoImagePath != null) {
      logoIndex = nextIndex++;
      args.addAll(['-i', settings.logoImagePath!]);
    }
    int? qrIndex;
    if (settings.showQrCode && qrAssetPath != null) {
      qrIndex = nextIndex++;
      args.addAll(['-i', qrAssetPath]);
    }

    final filterComplex = _buildFilterComplex(
      settings: settings,
      width: width,
      height: height,
      logoIndex: logoIndex,
      qrIndex: qrIndex,
      outputDurationSeconds: trim.duration,
    );

    final hasAudioFade =
        settings.fadeInSeconds > 0 || settings.fadeOutSeconds > 0;

    args.addAll(['-filter_complex', filterComplex]);
    args.addAll(['-map', '[outv]', '-map', hasAudioFade ? '[outa]' : '0:a']);
    args.addAll(['-c:v', videoCodec, '-pix_fmt', 'yuv420p']);
    if (settings.losslessAudio) {
      // Uncompressed PCM - no lossy audio generation on top of the source
      // file. Requires a .mov container; VideoRenderService picks the output
      // extension to match this flag.
      args.addAll(['-c:a', 'pcm_s16le']);
    } else {
      // 320k is the practical ceiling for AAC - used for platforms (e.g.
      // Spotify Canvas) that strictly require an MP4/AAC file.
      args.addAll(['-c:a', 'aac', '-b:a', '320k']);
    }
    args.addAll(['-shortest', '-movflags', '+faststart']);
    args.add(outputPath);

    return args;
  }

  /// Builds a fast single-frame preview: the same filter graph (so the
  /// preview is pixel-accurate, not a mockup), sought to a representative
  /// timestamp, outputting one PNG instead of an encoded video+audio mux.
  List<String> buildPreviewFrameArgs({
    required RenderSettings settings,
    required int width,
    required int height,
    required double audioDurationSeconds,
    required String outputPngPath,
    String? qrAssetPath,
    double? seekSeconds,
  }) {
    final seek =
        seekSeconds ??
        (audioDurationSeconds * 0.25).clamp(0, audioDurationSeconds);

    final args = <String>['-y', '-ss', seek.toStringAsFixed(3)];
    args.addAll(['-i', settings.audioPath]); // input 0: audio
    args.addAll([
      '-loop',
      '1',
      '-i',
      settings.imagePath,
    ]); // input 1: cover image

    int nextIndex = 2;
    int? logoIndex;
    if (settings.showLogo && settings.logoImagePath != null) {
      logoIndex = nextIndex++;
      args.addAll(['-i', settings.logoImagePath!]);
    }
    int? qrIndex;
    if (settings.showQrCode && qrAssetPath != null) {
      qrIndex = nextIndex++;
      args.addAll(['-i', qrAssetPath]);
    }

    final filterComplex = _buildFilterComplex(
      settings: settings,
      width: width,
      height: height,
      logoIndex: logoIndex,
      qrIndex: qrIndex,
      outputDurationSeconds: audioDurationSeconds,
    );

    args.addAll(['-filter_complex', filterComplex]);
    args.addAll(['-map', '[outv]', '-frames:v', '1']);
    args.add(outputPngPath);

    return args;
  }

  _Trim _resolveTrim(
    RenderSettings settings,
    double audioDurationSeconds,
    double? fixedLoopSeconds,
  ) {
    if (fixedLoopSeconds != null) {
      final start = settings.trimStartSeconds;
      return _Trim(applyTrim: true, start: start, duration: fixedLoopSeconds);
    }
    if (settings.fullDuration) {
      return _Trim(applyTrim: false, start: 0, duration: audioDurationSeconds);
    }
    final start = settings.trimStartSeconds;
    final duration =
        settings.trimDurationSeconds ?? (audioDurationSeconds - start);
    return _Trim(applyTrim: true, start: start, duration: duration);
  }

  String _buildFilterComplex({
    required RenderSettings settings,
    required int width,
    required int height,
    int? logoIndex,
    int? qrIndex,
    required double outputDurationSeconds,
  }) {
    final parts = <String>[];
    const imgIdx = 1;
    var labelCounter = 0;
    String nextLabel(String prefix) => '$prefix${labelCounter++}';

    parts.add(
      "[$imgIdx:v]scale=$width:$height:force_original_aspect_ratio=increase,"
      "crop=$width:$height,boxblur=${_fmt(settings.blurRadius)}:1[bg]",
    );
    String base = 'bg';

    if (settings.showCover) {
      // Cap the sharp cover to a fraction of the shorter frame side, so a
      // visible blurred border always shows around it - without this cap, a
      // cover close to (or larger than) the target resolution would scale up
      // to fill the entire frame edge-to-edge, hiding the blur entirely.
      // Never upscale past the source's own resolution ('min(...,iw)').
      final coverMaxSize =
          (width < height ? width : height) * settings.coverSizeFraction;
      base = _addPositionedOverlay(
        parts,
        base: base,
        sourceLabel: '$imgIdx:v',
        scaleExpr: "'min(${_fmt(coverMaxSize)},iw)':-1",
        transform: settings.coverTransform,
        nextLabel: nextLabel,
      );
    }

    if (settings.showLogo && logoIndex != null) {
      base = _addPositionedOverlay(
        parts,
        base: base,
        sourceLabel: '$logoIndex:v',
        scaleExpr: "round($width*0.15):-1",
        transform: settings.logoTransform,
        nextLabel: nextLabel,
      );
    }

    if (settings.showQrCode && qrIndex != null) {
      base = _addPositionedOverlay(
        parts,
        base: base,
        sourceLabel: '$qrIndex:v',
        scaleExpr: "round($width*0.18):-1",
        transform: settings.qrTransform,
        nextLabel: nextLabel,
      );
    }

    base = _addVisualizerStage(
      parts,
      base: base,
      settings: settings,
      width: width,
      height: height,
    );

    if (settings.showText && settings.textContent.trim().isNotEmpty) {
      final text = _escapeDrawtext(settings.textContent);
      final t = settings.textTransform;
      final label = nextLabel('withtext');
      parts.add(
        "[$base]drawtext=text='$text':fontcolor=white:fontsize=48:"
        "x='(W*${_fmt(t.dx)})-text_w/2':y='(H*${_fmt(t.dy)})-text_h/2':"
        "box=1:boxcolor=black@0.4:boxborderw=12[$label]",
      );
      base = label;
    }

    if (settings.vintageEffect) {
      final label = nextLabel('vintage');
      parts.add(
        "[$base]eq=contrast=0.95:saturation=0.82,"
        "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131:0,"
        "vignette=PI/5,noise=alls=6:allf=t[$label]",
      );
      base = label;
    }

    final videoFade = _buildFadeFilter(
      settings.fadeInSeconds,
      settings.fadeOutSeconds,
      outputDurationSeconds,
      isAudio: false,
    );
    parts.add(
      videoFade != null
          ? "[$base]$videoFade,format=yuv420p[outv]"
          : "[$base]format=yuv420p[outv]",
    );

    final audioFade = _buildFadeFilter(
      settings.fadeInSeconds,
      settings.fadeOutSeconds,
      outputDurationSeconds,
      isAudio: true,
    );
    if (audioFade != null) {
      parts.add("[0:a]$audioFade[outa]");
    }

    return parts.join(';');
  }

  /// Scales [sourceLabel] to [scaleExpr], optionally rotates it around its
  /// own center (transparent fill, so corners don't show as black boxes),
  /// then overlays it onto `base` centered at the transform's fractional
  /// (dx, dy) position of the frame. Returns the new base label.
  String _addPositionedOverlay(
    List<String> parts, {
    required String base,
    required String sourceLabel,
    required String scaleExpr,
    required ElementTransform transform,
    required String Function(String) nextLabel,
  }) {
    final scaled = nextLabel('scaled');
    parts.add("[$sourceLabel]scale=$scaleExpr,format=rgba[$scaled]");

    var elementLabel = scaled;
    if (transform.rotationDegrees != 0) {
      final rotated = nextLabel('rotated');
      final radians = transform.rotationDegrees * math.pi / 180.0;
      parts.add(
        "[$scaled]rotate=${_fmt(radians)}:c=none:ow=rotw:oh=roth[$rotated]",
      );
      elementLabel = rotated;
    }

    final composited = nextLabel('positioned');
    parts.add(
      "[$base][$elementLabel]overlay=x='(W*${_fmt(transform.dx)})-w/2':y='(H*${_fmt(transform.dy)})-h/2'[$composited]",
    );
    return composited;
  }

  /// Builds a `fade`/`afade` filter chain (video/audio respectively) for the
  /// configured fade-in/fade-out durations, or null if neither is set.
  String? _buildFadeFilter(
    double fadeIn,
    double fadeOut,
    double totalDuration, {
    required bool isAudio,
  }) {
    if (fadeIn <= 0 && fadeOut <= 0) return null;
    final filterName = isAudio ? 'afade' : 'fade';
    final stages = <String>[];
    if (fadeIn > 0) {
      stages.add('$filterName=t=in:st=0:d=${_fmt(fadeIn)}');
    }
    if (fadeOut > 0) {
      final start = (totalDuration - fadeOut).clamp(0.0, totalDuration);
      stages.add('$filterName=t=out:st=${_fmt(start)}:d=${_fmt(fadeOut)}');
    }
    return stages.join(',');
  }

  /// Adds the audio-reactive visualizer stage(s) and returns the new base label.
  String _addVisualizerStage(
    List<String> parts, {
    required String base,
    required RenderSettings settings,
    required int width,
    required int height,
  }) {
    final color = settings.visualizerColorHex;
    // 0.0-1.0 -> showfreqs' averaging frame count (2-16). Higher averages
    // more frames together, so bars rise/fall smoothly instead of jittering
    // frame to frame.
    final averaging = (2 + settings.visualizerSmoothness.clamp(0, 1) * 14)
        .round();

    String vizExpr(int vw, int vh) {
      switch (settings.style) {
        case VisualizerStyle.bars:
          return "showfreqs=s=${vw}x$vh:mode=bar:colors=$color:averaging=$averaging:win_func=hann";
        case VisualizerStyle.lineSpectrum:
          return "showfreqs=s=${vw}x$vh:mode=line:colors=$color:averaging=$averaging:win_func=hann";
        case VisualizerStyle.fluidWave:
          return "showwaves=s=${vw}x$vh:mode=cline:colors=$color";
        case VisualizerStyle.oscilloscope:
          return "avectorscope=s=${vw}x$vh:zoom=1.5";
      }
    }

    // colorkey turns the visualizer filter's black canvas transparent so only
    // the drawn bars/wave/scope composite over the background+cover.
    String rawVizFilter(int vw, int vh) =>
        "[0:a]${vizExpr(vw, vh)},colorkey=0x000000:0.15:0.1";

    switch (settings.placement) {
      case VisualizerPlacement.bottomBand:
        {
          final vh = (height * 0.22).round();
          parts.add("${rawVizFilter(width, vh)}[viz]");
          parts.add("[$base][viz]overlay=0:H-h[withviz]");
          return 'withviz';
        }
      case VisualizerPlacement.sideBorder:
        {
          final vw = (width * 0.12).round();
          parts.add("${rawVizFilter(vw, height)}[viz]");
          parts.add("[$base][viz]overlay=0:0[withviz]");
          return 'withviz';
        }
      case VisualizerPlacement.dualMirroredBottom:
        {
          final vh = (height * 0.22).round();
          final vhHalf = (vh / 2).round();
          parts.add("${rawVizFilter(width, vhHalf)}[vizraw]");
          parts.add('[vizraw]split=2[vsrc1][vsrc2]');
          parts.add('[vsrc2]vflip[vsrc2f]');
          parts.add('[vsrc1][vsrc2f]vstack[viz]');
          parts.add("[$base][viz]overlay=0:H-h[withviz]");
          return 'withviz';
        }
      case VisualizerPlacement.fullFrameBorder:
        {
          final vh = (height * 0.12).round();
          parts.add("${rawVizFilter(width, vh)}[vizraw]");
          parts.add('[vizraw]split=2[vbot][vtopsrc]');
          parts.add('[vtopsrc]vflip[vtop]');
          parts.add("[$base][vbot]overlay=0:H-h[withbottom]");
          parts.add('[withbottom][vtop]overlay=0:0[withviz]');
          return 'withviz';
        }
      case VisualizerPlacement.ascendingCorner:
        {
          final vw = (width * 0.4).round();
          final vh = (height * 0.25).round();
          parts.add("${rawVizFilter(vw, vh)}[viz]");
          parts.add("[$base][viz]overlay=0:H-h[withviz]");
          return 'withviz';
        }
      case VisualizerPlacement.centeredBehindText:
        {
          final vw = (width * 0.55).round();
          final vh = (height * 0.30).round();
          parts.add("${rawVizFilter(vw, vh)}[viz]");
          parts.add("[$base][viz]overlay=(W-w)/2:(H-h)/2[withviz]");
          return 'withviz';
        }
      case VisualizerPlacement.coverCenterDualBars:
        {
          // Full-height bars hugging both edges, mirrored for symmetry,
          // leaving the cover (already composited into `base`, centered) as
          // the visual focal point in the middle.
          final vw = (width * 0.12).round();
          parts.add("${rawVizFilter(vw, height)}[vizraw]");
          parts.add('[vizraw]split=2[vleft][vrightsrc]');
          parts.add('[vrightsrc]hflip[vright]');
          parts.add("[$base][vleft]overlay=0:0[withleft]");
          parts.add('[withleft][vright]overlay=W-w:0[withviz]');
          return 'withviz';
        }
    }
  }

  String _escapeDrawtext(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(':', '\\:')
        .replaceAll("'", "\\'")
        .replaceAll('%', '\\%');
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}

class _Trim {
  final bool applyTrim;
  final double start;
  final double duration;
  const _Trim({
    required this.applyTrim,
    required this.start,
    required this.duration,
  });
}
