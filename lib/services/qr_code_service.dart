import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:qr/qr.dart';

import '../models/qr_caption_position.dart';

/// Generates a scannable QR code as a plain PNG file, using pure-Dart
/// encoding/rasterization (no Flutter widget tree needed) so it works
/// identically from the CLI and the GUI.
class QrCodeService {
  /// Renders [content] as a QR code PNG at roughly [sizePx] square and
  /// returns the written file's path. A white quiet zone is included around
  /// the modules, since QR scanners rely on it for reliable detection. If
  /// [captionText] is non-empty, it's baked into the same image above or
  /// below the code per [captionPosition] (e.g. "Scan to listen"), so the
  /// caption moves and rotates together with the QR code as one unit.
  Future<String> generateQrPng({
    required String content,
    required int sizePx,
    String captionText = '',
    QrCaptionPosition captionPosition = QrCaptionPosition.below,
  }) async {
    final qrCode = QrCode(
      payload: QrPayload.fromString(content),
      errorCorrectLevel: QrErrorCorrectLevel.medium,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;

    const quietZoneModules = 4;
    final totalModules = moduleCount + quietZoneModules * 2;
    final moduleSize = (sizePx / totalModules).round().clamp(1, 1 << 20);
    final qrSize = moduleSize * totalModules;

    final hasCaption = captionText.trim().isNotEmpty;
    final captionAreaHeight = hasCaption ? (qrSize * 0.16).round() : 0;
    final qrTop = hasCaption && captionPosition == QrCaptionPosition.above
        ? captionAreaHeight
        : 0;

    final canvas = img.Image(
      width: qrSize,
      height: qrSize + captionAreaHeight,
      numChannels: 3,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (!qrImage.isDark(row, col)) continue;
        final x = (col + quietZoneModules) * moduleSize;
        final y = qrTop + (row + quietZoneModules) * moduleSize;
        img.fillRect(
          canvas,
          x1: x,
          y1: y,
          x2: x + moduleSize - 1,
          y2: y + moduleSize - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }

    if (hasCaption) {
      final font = qrSize > 700 ? img.arial48 : img.arial24;
      final text = captionText.trim();
      final captionTop = captionPosition == QrCaptionPosition.above
          ? 0
          : qrSize;
      // x omitted -> drawString centers the text horizontally within the canvas.
      final y =
          captionTop + ((captionAreaHeight - font.lineHeight) / 2).round();
      img.drawString(
        canvas,
        text,
        font: font,
        y: y,
        color: img.ColorRgb8(0, 0, 0),
      );
    }

    final outputPath = p.join(
      Directory.systemTemp.path,
      'promo_qr_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await File(outputPath).writeAsBytes(img.encodePng(canvas));
    return outputPath;
  }
}
