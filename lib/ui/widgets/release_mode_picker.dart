import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/release_mode.dart';

/// Radio choice between the three release modes, each with a small icon
/// diagram showing what actually happens to the input files: how many
/// covers/songs go in, and whether that produces one combined video or one
/// independent video per song.
class ReleaseModePicker extends StatelessWidget {
  final ReleaseMode value;
  final ValueChanged<ReleaseMode> onChanged;

  const ReleaseModePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RadioGroup<ReleaseMode>(
      groupValue: value,
      onChanged: (v) => onChanged(v ?? value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReleaseModeTile(
            mode: ReleaseMode.single,
            title: l10n.releaseModeSingle,
            explanation: l10n.singleExplanation,
            songCount: 1,
            outputCount: 1,
          ),
          _ReleaseModeTile(
            mode: ReleaseMode.multiSong,
            title: l10n.releaseModeMultiSong,
            explanation: l10n.multiSongExplanation,
            songCount: 3,
            outputCount: 3,
          ),
          _ReleaseModeTile(
            mode: ReleaseMode.medley,
            title: l10n.releaseModeMedley,
            explanation: l10n.medleyExplanation,
            songCount: 3,
            outputCount: 1,
          ),
        ],
      ),
    );
  }
}

class _ReleaseModeTile extends StatelessWidget {
  final ReleaseMode mode;
  final String title;
  final String explanation;
  final int songCount;
  final int outputCount;

  const _ReleaseModeTile({
    required this.mode,
    required this.title,
    required this.explanation,
    required this.songCount,
    required this.outputCount,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ReleaseMode>(
      value: mode,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            _FlowDiagram(songCount: songCount, outputCount: outputCount),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                explanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A cover + N song icons -> an arrow -> M video icons, so "one song, one
/// video" vs "many songs, many videos" vs "many songs, one video" reads at a
/// glance without needing to parse a sentence.
class _FlowDiagram extends StatelessWidget {
  final int songCount;
  final int outputCount;

  const _FlowDiagram({required this.songCount, required this.outputCount});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.image_outlined, size: 20, color: color),
        const SizedBox(width: 2),
        _CountedIcon(icon: Icons.music_note, count: songCount, color: color),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward, size: 14, color: color),
        const SizedBox(width: 6),
        _CountedIcon(
          icon: Icons.movie_creation_outlined,
          count: outputCount,
          color: color,
        ),
      ],
    );
  }
}

/// One icon, with a "3+" badge overlaid when [count] is more than one -
/// stands in for "several" without literally drawing several icons.
class _CountedIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _CountedIcon({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 20, color: color),
        if (count > 1)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count+',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
