import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/render_template.dart';

/// A combo box of previously saved style templates (visualizer, colors,
/// overlays, platforms...) - picking one applies it onto the draft
/// immediately, so the same look can be reused across releases without
/// redoing every setting for each new cover image/song. Lives on the first
/// wizard step so the whole rest of the wizard (including release mode)
/// starts from the template.
class TemplateComboBox extends StatefulWidget {
  final List<RenderTemplate> templates;
  final ValueChanged<RenderTemplate> onApply;
  final ValueChanged<String> onDelete;

  const TemplateComboBox({
    super.key,
    required this.templates,
    required this.onApply,
    required this.onDelete,
  });

  @override
  State<TemplateComboBox> createState() => _TemplateComboBoxState();
}

class _TemplateComboBoxState extends State<TemplateComboBox> {
  String? _selectedName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Drop a selection that no longer exists (e.g. it was just deleted).
    if (_selectedName != null &&
        !widget.templates.any((t) => t.name == _selectedName)) {
      _selectedName = null;
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedName,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.loadTemplateButton,
              hintText: widget.templates.isEmpty ? l10n.noTemplatesSaved : null,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final template in widget.templates)
                DropdownMenuItem(
                  value: template.name,
                  child: Text(template.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: widget.templates.isEmpty
                ? null
                : (name) {
                    if (name == null) return;
                    setState(() => _selectedName = name);
                    final template = widget.templates.firstWhere(
                      (t) => t.name == name,
                    );
                    widget.onApply(template);
                  },
          ),
        ),
        if (_selectedName != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteTemplateTooltip,
            onPressed: () {
              final name = _selectedName!;
              setState(() => _selectedName = null);
              widget.onDelete(name);
            },
          ),
      ],
    );
  }
}
