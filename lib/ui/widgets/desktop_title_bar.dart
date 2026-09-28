import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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
/// **Windows / Linux:** A draggable bar with the app title and native-style
/// window control buttons (minimize / maximize / close).
///
/// **macOS:** `TitleBarStyle.hidden` + fullSizeContentView already makes
/// Flutter content fill the entire window with the traffic-light buttons
/// floating over it (drag/double-click-to-zoom handled natively in
/// MainFlutterWindow.swift) - this just reserves 28pt at the top so content
/// doesn't slide under those buttons.
///
/// **Mobile/web:** Returns an empty widget.
class DesktopTitleBar extends StatefulWidget {
  final String title;

  const DesktopTitleBar({super.key, required this.title});

  @override
  State<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends State<DesktopTitleBar> with WindowListener {
  // Manual double-tap detection for the drag area - avoids placing a
  // DoubleTapGestureRecognizer over the entire bar (which would delay the
  // window-control buttons by the double-tap timeout).
  DateTime? _lastDragAreaTap;

  bool _isMaximized = false;

  static bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

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
    if (_lastDragAreaTap != null && now.difference(_lastDragAreaTap!) < const Duration(milliseconds: 350)) {
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
    if (kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    // macOS: TitleBarStyle.hidden + fullSizeContentView means Flutter content
    // starts at y=0, with the traffic lights floating over the top-left area.
    // Drag and double-click-to-maximize are handled natively in
    // MainFlutterWindow.swift via NSEvent monitors - no Flutter gesture
    // detection needed here.
    if (Platform.isMacOS) {
      return const SizedBox(height: 28, width: double.infinity);
    }

    // Windows / Linux: full custom title bar.
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Window controls: completely outside the drag-area detector.
          _WindowControlButtons(isMaximized: _isMaximized, onToggleMaximize: _toggleMaximize),
        ],
      ),
    );
  }
}

/// Minimize / Maximize / Close buttons for Windows and Linux only.
class _WindowControlButtons extends StatelessWidget {
  final bool isMaximized;
  final VoidCallback onToggleMaximize;

  const _WindowControlButtons({required this.isMaximized, required this.onToggleMaximize});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyMedium?.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(Icons.minimize, size: 18, color: color), onPressed: () => windowManager.minimize()),
        IconButton(
          icon: Icon(windowMaximizeToggleIcon(isMaximized), size: isMaximized ? 15 : 18, color: color),
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
