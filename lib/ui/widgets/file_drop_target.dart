import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// A drag-and-drop + click-to-browse target for picking a single file.
/// Reused for the cover image, the optional logo image, and the audio file.
class FileDropTarget extends StatefulWidget {
  final String label;
  final String? selectedPath;
  final List<String> allowedExtensions;
  final ValueChanged<String> onFileSelected;

  const FileDropTarget({
    super.key,
    required this.label,
    required this.selectedPath,
    required this.allowedExtensions,
    required this.onFileSelected,
  });

  @override
  State<FileDropTarget> createState() => _FileDropTargetState();
}

class _FileDropTargetState extends State<FileDropTarget> {
  bool _dragging = false;

  Future<void> _browse() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
    );
    final path = result?.path;
    if (path != null) widget.onFileSelected(path);
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.selectedPath != null;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        if (details.files.isNotEmpty) {
          widget.onFileSelected(details.files.first.path);
        }
      },
      child: InkWell(
        onTap: _browse,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _dragging
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              width: _dragging ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(hasFile ? Icons.check_circle : Icons.upload_file),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasFile
                      ? widget.selectedPath!
                      : AppLocalizations.of(
                          context,
                        )!.dropFileHint(widget.label),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
