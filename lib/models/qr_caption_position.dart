import '../l10n/generated/app_localizations.dart';

enum QrCaptionPosition { below, above }

extension QrCaptionPositionLabel on QrCaptionPosition {
  String label(AppLocalizations l10n) {
    switch (this) {
      case QrCaptionPosition.below:
        return l10n.qrCaptionPositionBelow;
      case QrCaptionPosition.above:
        return l10n.qrCaptionPositionAbove;
    }
  }
}
