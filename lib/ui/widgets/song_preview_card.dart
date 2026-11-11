import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../l10n/generated/app_localizations.dart';
import '../../models/audio_info.dart';
import '../../services/audio_probe_service.dart';
import '../../services/ffmpeg_locator.dart';
import 'audio_preview_player.dart';

/// ffprobe details per file path, cached for the session so re-showing a
/// song (switching steps, re-rendering the list) doesn't re-probe it.
final audioInfoProvider = FutureProvider.family<AudioInfo, String>((ref, path) {
  return AudioProbeService(FfmpegLocator()).probeInfo(path);
});

/// A picked song's details (length, codec, sample rate, bit depth, channels,
/// bitrate, size), its waveform, and a play button. When [startSeconds] /
/// [endSeconds] mark an excerpt (medley), the waveform highlights it and
/// playback covers just that part.
class SongPreviewCard extends ConsumerWidget {
  final String audioPath;
  final double startSeconds;
  final double? endSeconds;
  final Color waveColor;

  /// Hide the file name header when the surrounding UI already shows it.
  final bool showFileName;

  const SongPreviewCard({
    super.key,
    required this.audioPath,
    this.startSeconds = 0,
    this.endSeconds,
    required this.waveColor,
    this.showFileName = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final info = ref.watch(audioInfoProvider(audioPath));
    final isExcerpt = startSeconds > 0 || endSeconds != null;

    return info.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(l10n.songInfoLoading, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l10n.songInfoError, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
      data: (info) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFileName || info.title != null) ...[
            Text(
              info.title != null
                  ? [info.artist, info.title].whereType<String>().join(' – ')
                  : p.basename(audioPath),
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final detail in _details(info, l10n))
                _DetailChip(text: detail),
            ],
          ),
          const SizedBox(height: 10),
          AudioPreviewPlayer(
            // Rebuild the player (fresh audio source) when the file changes.
            key: ValueKey(audioPath),
            audioPath: audioPath,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            totalDurationSeconds: info.durationSeconds,
            waveColor: waveColor,
            playLabel: isExcerpt ? null : l10n.playSongButton,
          ),
        ],
      ),
    );
  }

  List<String> _details(AudioInfo info, AppLocalizations l10n) {
    final details = <String>[_formatDuration(info.durationSeconds)];
    final codec = _codecLabel(info);
    details.add(codec);
    if (info.sampleRate != null) {
      final khz = info.sampleRate! / 1000;
      details.add(
        '${khz == khz.roundToDouble() ? khz.round() : khz.toStringAsFixed(1)} kHz',
      );
    }
    if (info.bitDepth != null) details.add('${info.bitDepth}-bit');
    if (info.channels != null) {
      details.add(switch (info.channels!) {
        1 => l10n.channelsMono,
        2 => l10n.channelsStereo,
        final n => l10n.channelsCount(n),
      });
    }
    if (info.bitRate != null) {
      details.add('${(info.bitRate! / 1000).round()} kbps');
    }
    if (info.sizeBytes != null) details.add(_formatSize(info.sizeBytes!));
    details.add(info.isLossless ? l10n.audioLossless : l10n.audioLossy);
    return details;
  }

  /// e.g. "WAV · PCM", "FLAC", "MP3", "AAC (M4A)".
  static String _codecLabel(AudioInfo info) {
    final codec = info.codecName;
    final container = info.formatName.toUpperCase();
    if (codec.startsWith('pcm_')) return '$container · PCM';
    final name = switch (codec) {
      'mp3' => 'MP3',
      'aac' => 'AAC',
      'flac' => 'FLAC',
      'alac' => 'ALAC',
      'vorbis' => 'Vorbis',
      'opus' => 'Opus',
      _ => codec.toUpperCase(),
    };
    return name == container || container.isEmpty ? name : '$name ($container)';
  }

  static String _formatDuration(double seconds) {
    final total = seconds.round();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = (total % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }

  static String _formatSize(int bytes) {
    const mb = 1024 * 1024;
    return bytes >= mb
        ? '${(bytes / mb).toStringAsFixed(1)} MB'
        : '${(bytes / 1024).round()} KB';
  }
}

class _DetailChip extends StatelessWidget {
  final String text;

  const _DetailChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
