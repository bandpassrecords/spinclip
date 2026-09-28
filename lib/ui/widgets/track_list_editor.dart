import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../l10n/generated/app_localizations.dart';
import '../../models/track.dart';

/// Lists the songs for multi-song/medley mode. In medley mode, each row
/// also exposes start/duration fields for that song's excerpt ("trecho").
class TrackListEditor extends StatelessWidget {
  final List<Track> tracks;
  final bool isMedley;
  final double defaultSnippetDuration;

  /// The release's shared cover image, shown as each track's thumbnail
  /// unless that track sets its own.
  final String? defaultImagePath;
  final ValueChanged<List<String>> onAddTracks;
  final void Function(int index) onRemoveTrack;
  final void Function(int index, Track track) onUpdateTrack;

  const TrackListEditor({
    super.key,
    required this.tracks,
    required this.isMedley,
    required this.defaultSnippetDuration,
    required this.defaultImagePath,
    required this.onAddTracks,
    required this.onRemoveTrack,
    required this.onUpdateTrack,
  });

  Future<void> _addSongs() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'flac', 'ogg', 'aiff', 'm4a'],
    );
    final paths = result.map((f) => f.path).whereType<String>().toList();
    if (paths.isNotEmpty) onAddTracks(paths);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tracks.length; i++)
          _TrackRow(
            index: i,
            track: tracks[i],
            isMedley: isMedley,
            defaultImagePath: defaultImagePath,
            onRemove: () => onRemoveTrack(i),
            onUpdate: (t) => onUpdateTrack(i, t),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addSongs,
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addSong),
        ),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  final int index;
  final Track track;
  final bool isMedley;
  final String? defaultImagePath;
  final VoidCallback onRemove;
  final ValueChanged<Track> onUpdate;

  const _TrackRow({
    required this.index,
    required this.track,
    required this.isMedley,
    required this.defaultImagePath,
    required this.onRemove,
    required this.onUpdate,
  });

  Future<void> _pickCover(BuildContext context) async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    final path = result?.path;
    if (path != null) onUpdate(track.copyWith(imagePath: path));
  }

  void _clearCover() {
    onUpdate(
      Track.withTitle(
        audioPath: track.audioPath,
        fullDuration: track.fullDuration,
        trimStartSeconds: track.trimStartSeconds,
        trimDurationSeconds: track.trimDurationSeconds,
        title: track.title,
      ),
    );
  }

  Widget _thumbnail(String? path) {
    const size = 40.0;
    if (path == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.image_outlined,
          size: 18,
          color: Colors.white54,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.broken_image_outlined,
            size: 18,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = p.basename(track.audioPath);
    final effectiveImagePath = track.imagePath ?? defaultImagePath;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. $name',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              children: [
                _thumbnail(effectiveImagePath),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    track.imagePath != null
                        ? p.basename(track.imagePath!)
                        : l10n.trackDefaultCoverHint,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _pickCover(context),
                  child: Text(l10n.trackSetCover),
                ),
                if (track.imagePath != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    tooltip: l10n.trackClearCoverTooltip,
                    visualDensity: VisualDensity.compact,
                    onPressed: _clearCover,
                  ),
              ],
            ),
            if (isMedley)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: track.trimStartSeconds.toString(),
                      decoration: InputDecoration(
                        labelText: l10n.trackStartSeconds,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final value = double.tryParse(v);
                        if (value != null) {
                          onUpdate(track.copyWith(trimStartSeconds: value));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: (track.trimDurationSeconds ?? 8).toString(),
                      decoration: InputDecoration(
                        labelText: l10n.trackExcerptDuration,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final value = double.tryParse(v);
                        if (value != null) {
                          onUpdate(
                            track.copyWith(
                              trimDurationSeconds: value,
                              fullDuration: false,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
