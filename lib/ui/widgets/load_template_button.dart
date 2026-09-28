import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/render_template.dart';

/// Loads a previously saved style template (visualizer, colors, overlays,
/// platforms...) onto the draft - lets the same look be reused across
/// releases without redoing every setting for each new cover image/song.
/// Lives on the first wizard step so the whole rest of the wizard (including
/// release mode) starts from the template.
class LoadTemplateButton extends StatelessWidget {
  final List<RenderTemplate> templates;
  final ValueChanged<RenderTemplate> onApply;
  final ValueChanged<String> onDelete;

  const LoadTemplateButton({
    super.key,
    required this.templates,
    required this.onApply,
    required this.onDelete,
  });

  Future<void> _showLoadDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noTemplatesSaved)));
      return;
    }
    final selected = await showDialog<RenderTemplate>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.loadTemplateButton),
        children: [
          for (final template in templates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, template),
              child: Row(
                children: [
                  Expanded(child: Text(template.name)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: l10n.deleteTemplateTooltip,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onDelete(template.name);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null) onApply(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: () => _showLoadDialog(context),
      icon: const Icon(Icons.folder_open, size: 18),
      label: Text(l10n.loadTemplateButton),
    );
  }
}
