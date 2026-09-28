import '../l10n/generated/app_localizations.dart';

enum VisualizerPlacement {
  bottomBand,
  sideBorder,
  dualMirroredBottom,
  fullFrameBorder,
  ascendingCorner,
  centeredBehindText,
  coverCenterDualBars,
}

extension VisualizerPlacementLabel on VisualizerPlacement {
  String label(AppLocalizations l10n) {
    switch (this) {
      case VisualizerPlacement.bottomBand:
        return l10n.placementBottomBand;
      case VisualizerPlacement.sideBorder:
        return l10n.placementSideBorder;
      case VisualizerPlacement.dualMirroredBottom:
        return l10n.placementDualMirroredBottom;
      case VisualizerPlacement.fullFrameBorder:
        return l10n.placementFullFrameBorder;
      case VisualizerPlacement.ascendingCorner:
        return l10n.placementAscendingCorner;
      case VisualizerPlacement.centeredBehindText:
        return l10n.placementCenteredBehindText;
      case VisualizerPlacement.coverCenterDualBars:
        return l10n.placementCoverCenterDualBars;
    }
  }
}
