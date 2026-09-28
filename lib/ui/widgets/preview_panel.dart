import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/render_settings.dart';
import '../../services/qr_code_service.dart';
import '../../state/providers.dart';

/// Renders a real, pixel-accurate still frame from the current settings (not
/// an illustrative mockup), refreshing automatically (debounced) whenever the
/// settings or target size change - navigating the wizard or tweaking a
/// slider updates it without needing a manual "generate" click.
class PreviewPanel extends ConsumerStatefulWidget {
  final RenderSettings? settings;
  final int width;
  final int height;

  const PreviewPanel({super.key, required this.settings, required this.width, required this.height});

  @override
  ConsumerState<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends ConsumerState<PreviewPanel> {
  static const _debounceDelay = Duration(milliseconds: 450);

  String? _imagePath;
  bool _loading = false;
  String? _error;

  Timer? _debounce;
  bool _regenerateAgainAfterCurrent = false;
  final _qrCodeService = QrCodeService();
  String? _lastQrAssetPath;

  @override
  void initState() {
    super.initState();
    if (widget.settings != null) _generate();
  }

  @override
  void didUpdateWidget(covariant PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        widget.settings != oldWidget.settings || widget.width != oldWidget.width || widget.height != oldWidget.height;
    if (!changed) return;

    _debounce?.cancel();
    if (widget.settings == null) return;
    _debounce = Timer(_debounceDelay, _generate);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final lastQr = _lastQrAssetPath;
    if (lastQr != null) {
      unawaited(File(lastQr).delete().catchError((_) => File(lastQr)));
    }
    super.dispose();
  }

  Future<void> _generate() async {
    final settings = widget.settings;
    if (settings == null) return;

    if (_loading) {
      // A newer change arrived mid-render - one more pass once this finishes,
      // rather than overlapping ffmpeg processes on the same temp file.
      _regenerateAgainAfterCurrent = true;
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Match the actual render pipeline: the QR overlay only appears if a
    // generated asset is actually handed to the filter graph (previously
    // missing here, which is why the QR code showed in the final render but
    // never in this preview).
    String? qrAssetPath;
    if (settings.showQrCode && settings.qrCodeContent.trim().isNotEmpty) {
      try {
        qrAssetPath = await _qrCodeService.generateQrPng(
          content: settings.qrCodeContent.trim(),
          sizePx: 512,
          captionText: settings.qrCaptionText,
          captionPosition: settings.qrCaptionPosition,
        );
      } catch (_) {
        // Fall through without a QR overlay rather than failing the whole preview.
      }
    }

    final service = ref.read(previewServiceProvider);
    final result = await service.generatePreview(
      settings: settings,
      width: widget.width,
      height: widget.height,
      qrAssetPath: qrAssetPath,
    );

    final previousImagePath = _imagePath;
    final previousQrAssetPath = _lastQrAssetPath;
    _lastQrAssetPath = qrAssetPath;

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _imagePath = result.imagePath;
      } else {
        _error = result.errorMessage;
      }
    });

    if (result.success && previousImagePath != null && previousImagePath != result.imagePath) {
      unawaited(File(previousImagePath).delete().catchError((_) => File(previousImagePath)));
    }
    if (previousQrAssetPath != null && previousQrAssetPath != qrAssetPath) {
      unawaited(File(previousQrAssetPath).delete().catchError((_) => File(previousQrAssetPath)));
    }

    if (_regenerateAgainAfterCurrent) {
      _regenerateAgainAfterCurrent = false;
      unawaited(_generate());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.settings != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: widget.width / widget.height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // A fresh file is written per generation, so bypass
                    // Flutter's image cache or a re-preview would show the
                    // previous frame under the same-looking widget.
                    child: Image.file(File(_imagePath!), key: ValueKey(_imagePath), fit: BoxFit.contain),
                  )
                else
                  Center(
                    child: Text(
                      ready
                          ? AppLocalizations.of(context)!.renderingPreview
                          : AppLocalizations.of(context)!.selectCoverAndAudioFirst,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_loading)
                  Container(
                    color: Colors.black38,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ],
    );
  }
}
