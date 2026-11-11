import 'dart:io';

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

  /// Show the picked file as an image thumbnail (for cover/logo pickers).
  final bool showImagePreview;

  const FileDropTarget({
    super.key,
    required this.label,
    required this.selectedPath,
    required this.allowedExtensions,
    required this.onFileSelected,
    this.showImagePreview = false,
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
              if (hasFile && widget.showImagePreview)
                _ImageThumbnail(path: widget.selectedPath!)
              else
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

class _ImageThumbnail extends StatelessWidget {
  final String path;

  const _ImageThumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(path),
        // Re-read when the same path is picked again after being edited.
        key: ValueKey(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: 192,
        errorBuilder: (_, _, _) => const SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
