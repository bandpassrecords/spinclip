import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class OutputDirectoryPicker extends StatelessWidget {
  final String? selectedPath;
  final ValueChanged<String> onDirectorySelected;

  const OutputDirectoryPicker({super.key, required this.selectedPath, required this.onDirectorySelected});

  Future<void> _browse() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) onDirectorySelected(path);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _browse,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.folder_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedPath ?? AppLocalizations.of(context)!.outputDirectoryDefault,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
