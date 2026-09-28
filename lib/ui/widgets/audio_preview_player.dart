import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/ffmpeg_locator.dart';
import '../../services/waveform_peaks_service.dart';
import 'waveform_painter.dart';

final waveformPeaksServiceProvider = Provider<WaveformPeaksService>((ref) {
  return WaveformPeaksService(FfmpegLocator());
});

/// Shows the track's waveform and lets the user play back just the selected
/// excerpt (startSeconds to endSeconds) - playback auto-stops and rewinds to
/// the start once it reaches the end of the selection, rather than playing
/// past it into the rest of the song.
class AudioPreviewPlayer extends ConsumerStatefulWidget {
  final String audioPath;
  final double startSeconds;
  final double? endSeconds;
  final double totalDurationSeconds;
  final Color waveColor;

  const AudioPreviewPlayer({
    super.key,
    required this.audioPath,
    required this.startSeconds,
    required this.endSeconds,
    required this.totalDurationSeconds,
    this.waveColor = const Color(0xFF33CCFF),
  });

  @override
  ConsumerState<AudioPreviewPlayer> createState() => _AudioPreviewPlayerState();
}

class _AudioPreviewPlayerState extends ConsumerState<AudioPreviewPlayer> {
  final _player = AudioPlayer();
  List<double>? _peaks;
  bool _loadingPeaks = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

  // Whether `_player` has ever had a source loaded (via play()). Calling
  // seek() before that hangs forever - it waits on a native "seek complete"
  // event that never fires without a source loaded on the platform side.
  bool _sourceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPeaks();
    _positionSub = _player.onPositionChanged.listen(_onPositionChanged);
    _completeSub = _player.onPlayerComplete.listen((_) => _stopAndRewind());
  }

  @override
  void didUpdateWidget(covariant AudioPreviewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      _stopAndRewind();
      _sourceLoaded = false;
      _peaks = null;
      _loadPeaks();
    }
  }

  Future<void> _loadPeaks() async {
    setState(() => _loadingPeaks = true);
    try {
      final peaks = await ref
          .read(waveformPeaksServiceProvider)
          .extractPeaks(widget.audioPath);
      if (!mounted) return;
      setState(() {
        _peaks = peaks;
        _loadingPeaks = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPeaks = false);
    }
  }

  void _onPositionChanged(Duration position) {
    if (!mounted) return;
    setState(() => _position = position);
    final end = widget.endSeconds;
    if (end != null && position.inMilliseconds >= (end * 1000).round()) {
      _stopAndRewind();
    }
  }

  Future<void> _stopAndRewind() async {
    if (_sourceLoaded) {
      await _player.pause();
      await _player.seek(
        Duration(milliseconds: (widget.startSeconds * 1000).round()),
      );
    }
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _position = Duration(milliseconds: (widget.startSeconds * 1000).round());
    });
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    // Restart from the selection's start if we're outside it (e.g. after it
    // finished, or the selection changed since we last played).
    final startMs = (widget.startSeconds * 1000).round();
    final endMs = widget.endSeconds != null
        ? (widget.endSeconds! * 1000).round()
        : null;
    final needsRestart =
        _position.inMilliseconds < startMs ||
        (endMs != null && _position.inMilliseconds >= endMs);

    if (!_sourceLoaded) {
      // First playback: play()'s own setSource -> seek -> resume sequencing
      // avoids calling seek() before a source is loaded on the platform
      // side, which otherwise hangs forever waiting for a "seek complete"
      // event that never fires.
      await _player.play(
        DeviceFileSource(widget.audioPath),
        position: Duration(milliseconds: startMs),
      );
      _sourceLoaded = true;
    } else {
      if (needsRestart) {
        await _player.seek(Duration(milliseconds: startMs));
      }
      await _player.resume();
    }
    setState(() => _isPlaying = true);
  }

  void _seekToFraction(double fraction) {
    if (!_sourceLoaded) return; // nothing loaded yet to seek within
    final target = fraction.clamp(0.0, 1.0) * widget.totalDurationSeconds;
    _player.seek(Duration(milliseconds: (target * 1000).round()));
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalDurationSeconds > 0
        ? widget.totalDurationSeconds
        : 1.0;
    final startFraction = (widget.startSeconds / total).clamp(0.0, 1.0);
    final endFraction = ((widget.endSeconds ?? total) / total).clamp(0.0, 1.0);
    final playheadFraction = (_position.inMilliseconds / 1000 / total).clamp(
      0.0,
      1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: _loadingPeaks || _peaks == null
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onTapUp: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    _seekToFraction(details.localPosition.dx / box.size.width);
                  },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: WaveformPainter(
                      peaks: _peaks!,
                      selectionStartFraction: startFraction,
                      selectionEndFraction: endFraction,
                      playheadFraction: _isPlaying ? playheadFraction : null,
                      barColor: widget.waveColor,
                      selectionOverlayColor: widget.waveColor.withAlpha(0x22),
                      playheadColor: widget.waveColor,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filled(
              onPressed: _peaks == null ? null : _togglePlay,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.previewExcerptButton),
          ],
        ),
      ],
    );
  }
}
