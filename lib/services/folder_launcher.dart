import 'dart:io';

/// Opens a folder in the OS's file manager (Explorer/Finder/whatever the
/// Linux desktop environment provides) - there's no cross-platform Flutter
/// API for this, so it's one Process.run per platform.
class FolderLauncher {
  Future<void> openFolder(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }
}
