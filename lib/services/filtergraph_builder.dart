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

    // Gaussian background blur. sigma = 0.8 x blurRadius visually matches the
    // box blur this replaced at the same slider value, so saved templates
    // keep roughly the same strength.
    final blurSigma = _fmt(
      double.parse((settings.blurRadius * 0.8).toStringAsFixed(2)),
    );
    parts.add(
      "[$imgIdx:v]scale=$width:$height:force_original_aspect_ratio=increase,"
      "crop=$width:$height,gblur=sigma=$blurSigma:steps=3[bg]",
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
        "[$base]eq=contrast=0.95:saturation=0.9,"
        // Full classic sepia (.393/.769/.189 etc.) blended 35% with the
        // original colors (65% identity), rather than applying it at full
        // strength - just a hint of warm/yellowed tone instead of a heavy
        // brown-orange cast.
        "colorchannelmixer=0.7876:0.2692:0.0662:0:0.1222:0.8901:0.0588:0:0.0952:0.1869:0.6959:0,"
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
    // showfreqs takes one colour per audio channel and draws any channel
    // without one in white - so a stereo track rendered the right channel as
    // white bars over the chosen colour. Repeat it for up to 7.1 audio.
    // With a gradient, everything is drawn white and then multiplied by the
    // gradient (see rawVizFilter), so shading like the cartoon outline
    // becomes a darker shade of the gradient.
    final useGradient =
        settings.visualizerGradient &&
        settings.style != VisualizerStyle.oscilloscope;
    final color = List.filled(
      8,
      useGradient ? '0xFFFFFF' : settings.visualizerColorHex,
    ).join('|');
    // 0.0-1.0 -> showfreqs' averaging frame count (1-7). Higher averages
    // more frames together, so bars rise/fall smoothly instead of jittering
    // frame to frame; kept low so bars still bounce with the beat (at 25 fps
    // the default 0.5 averages 4 frames, ~160 ms).
    final averaging = (1 + settings.visualizerSmoothness.clamp(0, 1) * 6)
        .round();

    // Spectrum styles show 60 Hz-16 kHz on a log axis. Resampling to 32 kHz
    // puts the top of the axis (Nyquist) at 16 kHz, the high-pass drops
    // DC/sub-bass rumble, and the log scale gives the bass - where most of a
    // song's energy is - more than the first sliver of the width, so it no
    // longer shows up as one huge bar on the far left.
    const spectrumPrefix = "aresample=32000,highpass=f=60:poles=2,";
    const spectrumScale = "fscale=log:win_size=2048";

    // Sensitivity. Bar heights are logarithmic over a fixed 120 dB range, so
    // a plain volume boost barely moves them (2x = 6 dB = 5% of the height).
    // Above 1.0 it instead zooms the amplitude axis k times around its middle
    // (-60 dB, where music typically sits): the spectrum is drawn k times
    // taller and the centre slice kept, so a typical level stays at
    // mid-height while louder/quieter moments swing further up and down.
    // Wave/scope styles draw amplitude linearly, so plain gain suits them.
    final sensitivity = settings.visualizerSensitivity.clamp(1.0, 3.0);
    final rangeZoom = sensitivity;
    final isSpectrum =
        settings.style != VisualizerStyle.fluidWave &&
        settings.style != VisualizerStyle.oscilloscope;
    final gain = _fmt(isSpectrum ? 1 : sensitivity);

    /// A showfreqs spectrum [w]x[vh] over 60 Hz-16 kHz, zoomed by
    /// [rangeZoom].
    String spectrum(int w, int vh, {String mode = 'bar', String extra = ''}) {
      final tallH = (vh * rangeZoom).round();
      return "${spectrumPrefix}showfreqs=s=${w}x$tallH:mode=$mode:colors=$color:averaging=$averaging:win_func=hann:$spectrumScale$extra,"
          "crop=$w:$vh:0:${(tallH - vh) ~/ 2}";
    }

    /// [count] discrete, flat-topped spectrum bars filling a [vw]x[vh] box:
    /// showfreqs renders one pixel column per bar, which is stretched with
    /// nearest-neighbour scaling so each column becomes a solid bar, then
    /// gaps are cut between them. Any leftover width (vw not divisible by the
    /// count) is split evenly on both sides.
    String discreteBars(
      int vw,
      int vh, {
      required int count,
      required int Function(int slot) gapFor,
      String extraOptions = '',
    }) {
      final n = count.clamp(4, math.max(4, vw ~/ 3)).toInt();
      final slot = vw ~/ n;
      final total = slot * n;
      return "${spectrum(n, vh, extra: extraOptions)},"
          "scale=$total:$vh:flags=neighbor,"
          "drawgrid=w=$slot:h=0:t=${gapFor(slot)}:c=black@1,"
          "pad=$vw:$vh:${(vw - total) ~/ 2}:0:black";
    }

    int thinGap(int slot) => (slot * 0.2).round().clamp(1, 12);

    String barsExpr(int vw, int vh) => settings.visualizerBarCount > 0
        ? discreteBars(
            vw,
            vh,
            count: settings.visualizerBarCount,
            gapFor: thinGap,
          )
        : spectrum(vw, vh);

    String vizExpr(int vw, int vh) {
      switch (settings.style) {
        case VisualizerStyle.bars:
          return barsExpr(vw, vh);
        case VisualizerStyle.lineSpectrum:
          return spectrum(vw, vh, mode: 'line');
        case VisualizerStyle.fluidWave:
          // draw=full: the default "scale" mode dims each pixel, so the wave
          // never reached the chosen colour (and a gradient turned muddy).
          return "showwaves=s=${vw}x$vh:mode=cline:colors=$color:draw=full";
        case VisualizerStyle.oscilloscope:
          return "avectorscope=s=${vw}x$vh:zoom=1.5";
        case VisualizerStyle.neonGlow:
          // Plain bars here; the glow is added over the whole frame below.
          return barsExpr(vw, vh);
        case VisualizerStyle.cartoon:
          // Chunky separated bars with a darker-shade outline (sticker look).
          // Auto: 32 bars, fewer in narrow boxes so each stays >= 12px wide.
          final count = settings.visualizerBarCount > 0
              ? settings.visualizerBarCount
              : math.min(32, vw ~/ 12);
          final bars = discreteBars(
            vw,
            vh,
            count: count,
            gapFor: (slot) => (slot * 0.2).round().clamp(2, 12),
            extraOptions: ':ascale=cbrt',
          );
          return "$bars,format=rgba,split=2[cart0][cart1];"
              "[cart1]dilation,dilation,dilation,lutrgb=r='val*0.3':g='val*0.3':b='val*0.3'[cartout];"
              "[cart0]colorkey=0x000000:0.15:0.1[cartfill];"
              "[cartout][cartfill]overlay=format=auto,format=rgba";
      }
    }

    // colorkey turns the visualizer filter's black canvas transparent so only
    // the drawn bars/wave/scope composite over the background+cover.
    // The downmix and volume gain only feed the visualizer; the soundtrack is
    // mapped from the untouched input. Mixing to mono gives one clean shape
    // instead of two overlaid channels with ragged edges; the oscilloscope
    // keeps stereo since it plots left against right.
    final downmix = settings.style == VisualizerStyle.oscilloscope
        ? ''
        : 'aformat=channel_layouts=mono,';
    String rawVizFilter(int vw, int vh) {
      final viz =
          "[0:a]${downmix}volume=$gain,${vizExpr(vw, vh)},colorkey=0x000000:0.15:0.1";
      if (!useGradient) return viz;
      // Base colour at the bottom of the box (where bars start, which the
      // placements flip to face the frame edge) to the second colour at the
      // top (bar tips). The centred fluid wave instead goes edge -> centre ->
      // edge. Multiply runs in planar RGB; in YUV it would mix the chroma
      // planes and produce the wrong colours.
      final c0 = settings.visualizerColorHex;
      final c1 = settings.visualizerGradientColorHex;
      final stops = settings.style == VisualizerStyle.fluidWave
          ? "c0=$c0:c1=$c1:c2=$c0:nb_colors=3"
          : "c0=$c0:c1=$c1:nb_colors=2";
      return "$viz,format=gbrap[vizwhite];"
          "gradients=s=${vw}x$vh:$stops:"
          "x0=0:y0=${vh - 1}:x1=0:y1=0:speed=0:r=25,format=gbrap[vizgrad];"
          "[vizwhite][vizgrad]blend=all_mode=multiply:shortest=1";
    }

    if (settings.style != VisualizerStyle.neonGlow) {
      return _placeVisualizer(
        parts,
        onto: base,
        placement: settings.placement,
        rawVizFilter: rawVizFilter,
        width: width,
        height: height,
      );
    }

    // Neon Glow: place the bars on a transparent full-frame layer first, then
    // blur that whole layer, so the glow spills past the visualizer's own box
    // onto the background (and between mirrored halves). The glow is a solid
    // layer of the bar colour whose *transparency* is the blurred bar shape -
    // a tight core plus a wide soft halo - so it fades into the cover instead
    // of darkening it. Capped at ~65% opacity so the bars stay crisp in front.
    parts.add("[$base]split=2[neonbase][neoncanvassrc]");
    parts.add(
      "[neoncanvassrc]format=rgba,colorchannelmixer=rr=0:gg=0:bb=0:aa=0[neoncanvas]",
    );
    final layer = _placeVisualizer(
      parts,
      onto: 'neoncanvas',
      placement: settings.placement,
      rawVizFilter: rawVizFilter,
      width: width,
      height: height,
    );
    // The mask is built at half resolution (a soft glow looks the same, and
    // blurring the full frame is the expensive part), so sigmas are halved.
    final tightSigma = (height * 0.0045).clamp(2, 8).round();
    final wideSigma = (height * 0.0165).clamp(5, 30).round();
    final rgb =
        int.tryParse(
          settings.visualizerColorHex.replaceFirst('0x', ''),
          radix: 16,
        ) ??
        0;
    final r = (rgb >> 16) & 255, g = (rgb >> 8) & 255, b = rgb & 255;
    parts.add("[$layer]format=rgba,split=4[neont][neonw][neonc][neonbars]");
    parts.add(
      "[neont]alphaextract,scale=iw/2:ih/2,dilation,dilation,gblur=sigma=$tightSigma:steps=3[neontm]",
    );
    parts.add(
      "[neonw]alphaextract,scale=iw/2:ih/2,dilation,dilation,dilation,gblur=sigma=$wideSigma:steps=3[neonwm]",
    );
    parts.add(
      "[neonwm][neontm]blend=all_mode=lighten,lut=y='min(val*1.8,170)',scale=${width}x$height[neonmask]",
    );
    parts.add("[neonc]lutrgb=r=$r:g=$g:b=$b[neonsolid]");
    parts.add("[neonsolid][neonmask]alphamerge[neonglow]");
    parts.add("[neonbase][neonglow]overlay[neonwithglow]");
    parts.add("[neonwithglow][neonbars]overlay[withneon]");
    return 'withneon';
  }

  /// Composites the visualizer onto [onto] at [placement] and returns the new
  /// label.
  String _placeVisualizer(
    List<String> parts, {
    required String onto,
    required VisualizerPlacement placement,
    required String Function(int vw, int vh) rawVizFilter,
    required int width,
    required int height,
  }) {
    final base = onto;
    switch (placement) {
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
