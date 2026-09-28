import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// One line of the final wizard step's summary: a step's name, its current
/// value at a glance, and a jump-back-to-edit-it button - so the user can
/// double check the whole configuration without paging back through every
/// step, and fix just the one thing that's wrong.
class ReviewSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const ReviewSummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: l10n.reviewEditTooltip,
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 8),
          ),
        ],
      ),
    );
  }
}
