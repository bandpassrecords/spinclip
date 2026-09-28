import '../l10n/generated/app_localizations.dart';

enum VisualizerStyle { bars, lineSpectrum, fluidWave, oscilloscope }

extension VisualizerStyleLabel on VisualizerStyle {
  String label(AppLocalizations l10n) {
    switch (this) {
      case VisualizerStyle.bars:
        return l10n.styleBars;
      case VisualizerStyle.lineSpectrum:
        return l10n.styleLineSpectrum;
      case VisualizerStyle.fluidWave:
        return l10n.styleFluidWave;
      case VisualizerStyle.oscilloscope:
        return l10n.styleOscilloscope;
    }
  }
}
