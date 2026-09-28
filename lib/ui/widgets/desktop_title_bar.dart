import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/providers.dart';

/// Icon for the maximize/restore window-control button: a single square
/// when the window can still be maximized, two overlapping squares once it
/// already is (native Windows/Linux window-control convention).
@visibleForTesting
IconData windowMaximizeToggleIcon(bool isMaximized) =>
    isMaximized ? Icons.filter_none : Icons.crop_square_sharp;

/// A cross-platform custom title bar, replacing the OS's native one
/// (`TitleBarStyle.hidden` in main.dart) so the whole window looks
/// consistent with the rest of the app rather than mixing a native chrome
/// bar with Flutter content below it.
///
/// **Windows / Linux:** A draggable bar with the app title, a language
/// switcher, and native-style window control buttons (minimize / maximize /
/// close).
///
/// **macOS:** `TitleBarStyle.hidden` + fullSizeContentView already makes
/// Flutter content fill the entire window with the traffic-light buttons
/// floating over the top-left (drag/double-click-to-zoom handled natively in
/// MainFlutterWindow.swift) - this reserves 28pt at the top, with the
/// language switcher right-aligned clear of those buttons.
///
/// **Mobile/web:** Returns an empty widget.
class DesktopTitleBar extends ConsumerStatefulWidget {
  final String title;

  const DesktopTitleBar({super.key, required this.title});

  @override
  ConsumerState<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends ConsumerState<DesktopTitleBar>
    with WindowListener {
  // Manual double-tap detection for the drag area - avoids placing a
  // DoubleTapGestureRecognizer over the entire bar (which would delay the
  // window-control buttons by the double-tap timeout).
  DateTime? _lastDragAreaTap;

  bool _isMaximized = false;

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
      windowManager.isMaximized().then((maximized) {
        if (mounted) setState(() => _isMaximized = maximized);
      });
    }
  }

  @override
  void dispose() {
    if (_isDesktop) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  void _handleDragAreaTap() {
    final now = DateTime.now();
    if (_lastDragAreaTap != null &&
        now.difference(_lastDragAreaTap!) < const Duration(milliseconds: 350)) {
      _lastDragAreaTap = null;
      _toggleMaximize();
    } else {
      _lastDragAreaTap = now;
    }
  }

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      windowManager.restore();
    } else {
      windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    // macOS: TitleBarStyle.hidden + fullSizeContentView means Flutter content
    // starts at y=0, with the traffic lights floating over the top-left area.
    // Drag and double-click-to-maximize are handled natively in
    // MainFlutterWindow.swift via NSEvent monitors - no Flutter gesture
    // detection needed here. The language switcher sits on the right, clear
    // of the traffic lights.
    if (Platform.isMacOS) {
      return const SizedBox(
        height: 28,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 8),
            child: _LanguageSwitcher(),
          ),
        ),
      );
    }

    // Windows / Linux: full custom title bar.
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      height: 40,
      child: Row(
        children: [
          // Drag area: pan-to-drag + manual double-tap-to-maximize. The
          // GestureDetector here covers only the title/drag region, NOT the
          // window-control buttons, so DoubleTapGestureRecognizer never
          // delays their tap callbacks.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              onTapDown: (_) => _handleDragAreaTap(),
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Language switcher + window controls: completely outside the
          // drag-area detector.
          const _LanguageSwitcher(),
          _WindowControlButtons(
            isMaximized: _isMaximized,
            onToggleMaximize: _toggleMaximize,
          ),
        ],
      ),
    );
  }
}

/// A globe icon that opens a menu of the app's supported languages, plus a
/// "follow system" option. Picking one sets `localeProvider`, which
/// `SpinclipApp` feeds straight into `MaterialApp.locale`.
class _LanguageSwitcher extends ConsumerWidget {
  const _LanguageSwitcher();

  static const _labels = {'en': 'English', 'pt': 'Português', 'es': 'Español'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    // The actually-active locale, whether the user picked one or it fell
    // back to the system's - this is what the label should always reflect.
    final effectiveLocale = Localizations.localeOf(context);
    final currentLabel =
        _labels[effectiveLocale.languageCode] ??
        effectiveLocale.languageCode.toUpperCase();
    final color = Theme.of(context).textTheme.bodyMedium?.color;
    return PopupMenuButton<Locale?>(
      tooltip: '',
      onSelected: (locale) =>
          ref.read(localeProvider.notifier).setLocale(locale),
      itemBuilder: (context) => [
        CheckedPopupMenuItem<Locale?>(
          value: null,
          checked: currentLocale == null,
          child: const Text('System'),
        ),
        const PopupMenuDivider(),
        for (final supported in AppLocalizations.supportedLocales)
          CheckedPopupMenuItem<Locale?>(
            value: supported,
            checked: currentLocale?.languageCode == supported.languageCode,
            child: Text(
              _labels[supported.languageCode] ?? supported.languageCode,
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 16, color: color),
            const SizedBox(width: 4),
            Text(currentLabel, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Minimize / Maximize / Close buttons for Windows and Linux only.
class _WindowControlButtons extends StatelessWidget {
  final bool isMaximized;
  final VoidCallback onToggleMaximize;

  const _WindowControlButtons({
    required this.isMaximized,
    required this.onToggleMaximize,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyMedium?.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.minimize, size: 18, color: color),
          onPressed: () => windowManager.minimize(),
        ),
        IconButton(
          icon: Icon(
            windowMaximizeToggleIcon(isMaximized),
            size: isMaximized ? 15 : 18,
            color: color,
          ),
          onPressed: onToggleMaximize,
        ),
        IconButton(
          icon: Icon(Icons.close, size: 18, color: color),
          onPressed: () => windowManager.close(),
          highlightColor: const Color(0xFFC42B1C),
        ),
      ],
    );
  }
}
