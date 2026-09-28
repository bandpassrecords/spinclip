import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/render_template.dart';

/// Save the current style (visualizer, colors, overlays, platforms...) as a
/// named template, or load a previously saved one back onto the draft -
/// lets the same look be reused across releases without redoing every
/// setting for each new cover image/song.
class TemplateControls extends StatelessWidget {
  final List<RenderTemplate> templates;
  final ValueChanged<RenderTemplate> onApply;
  final ValueChanged<String> onSaveAs;
  final ValueChanged<String> onDelete;

  const TemplateControls({
    super.key,
    required this.templates,
    required this.onApply,
    required this.onSaveAs,
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

  Future<void> _showSaveDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.saveAsTemplateButton),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.templateNameLabel),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) onSaveAs(name.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showLoadDialog(context),
          icon: const Icon(Icons.folder_open, size: 18),
          label: Text(l10n.loadTemplateButton),
        ),
        OutlinedButton.icon(
          onPressed: () => _showSaveDialog(context),
          icon: const Icon(Icons.save_outlined, size: 18),
          label: Text(l10n.saveAsTemplateButton),
        ),
      ],
    );
  }
}
