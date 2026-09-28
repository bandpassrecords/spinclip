import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: const Size(1280, 800),
    minimumSize: const Size(1024, 680),
    center: true,
    title: 'Spinclip',
    // macOS: hidden style = fullSizeContentView + transparent title bar, with
    // the traffic lights floating over Flutter content (DesktopTitleBar
    // reserves space for them). Windows/Linux debug: normal, for easy
    // development. Windows/Linux release: hidden, replaced by
    // DesktopTitleBar's custom Flutter title bar.
    titleBarStyle: (!Platform.isMacOS && kDebugMode)
        ? TitleBarStyle.normal
        : TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: SpinclipApp()));
}
