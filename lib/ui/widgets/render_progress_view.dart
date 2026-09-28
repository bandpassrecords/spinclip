import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/render_progress.dart';
import '../../services/folder_launcher.dart';

class RenderProgressView extends StatelessWidget {
  final RenderProgress progress;
  final VoidCallback onCancel;
  final _folderLauncher = FolderLauncher();

  RenderProgressView({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (progress.phase) {
      case RenderPhase.idle:
        return const SizedBox.shrink();
      case RenderPhase.probing:
        return const LinearProgressIndicator();
      case RenderPhase.rendering:
        final percent = (progress.percent * 100).round().toString();
        final label = progress.presetCount != null
            ? l10n.renderProgressLabel(
                (progress.presetIndex ?? 0) + 1,
                progress.presetCount!,
                progress.currentPresetName ?? '',
                percent,
              )
            : l10n.renderingGeneric;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: progress.percent),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop),
              label: Text(l10n.cancel),
            ),
          ],
        );
      case RenderPhase.done:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.renderDone(progress.outputPath ?? ''),
              style: const TextStyle(color: Colors.greenAccent),
            ),
            if (progress.outputPath != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    _folderLauncher.openFolder(progress.outputPath!),
                icon: const Icon(Icons.folder_open),
                label: Text(l10n.openOutputFolder),
              ),
            ],
          ],
        );
      case RenderPhase.error:
        return Text(
          l10n.renderError(progress.message ?? ''),
          style: const TextStyle(color: Colors.redAccent),
        );
      case RenderPhase.cancelled:
        return Text(l10n.renderCancelled);
    }
  }
}
