import 'package:path/path.dart' as p;

/// Sanitizes [name] for use as a filesystem folder name, replacing
/// characters that are invalid on Windows (and awkward elsewhere) with '_'.
String sanitizeFolderName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
  return cleaned.isEmpty ? 'release' : cleaned;
}

/// The subfolder a render session writes into: the user's own override if
/// they typed one, otherwise derived from the cover image's filename so
/// different releases naturally land in different folders instead of
/// overwriting each other - falling back to a generic name only when
/// there's no shared cover image at all (e.g. a multi-song batch where
/// every track supplies its own).
String resolveOutputSubfolderName({
  required String customName,
  required String? imagePath,
}) {
  final trimmed = customName.trim();
  if (trimmed.isNotEmpty) return sanitizeFolderName(trimmed);
  if (imagePath != null) {
    return sanitizeFolderName(p.basenameWithoutExtension(imagePath));
  }
  return 'release';
}
