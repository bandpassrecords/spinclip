import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class PerformancePanel extends StatelessWidget {
  final bool useHardwareAcceleration;
  final ValueChanged<bool> onHardwareAccelerationChanged;
  final bool losslessAudio;
  final ValueChanged<bool> onLosslessAudioChanged;

  const PerformancePanel({
    super.key,
    required this.useHardwareAcceleration,
    required this.onHardwareAccelerationChanged,
    required this.losslessAudio,
    required this.onLosslessAudioChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.hardwareAcceleration),
          subtitle: Text(l10n.hardwareAccelerationSubtitle),
          value: useHardwareAcceleration,
          onChanged: onHardwareAccelerationChanged,
        ),
        SwitchListTile(
          title: Text(l10n.losslessAudio),
          subtitle: Text(l10n.losslessAudioSubtitle),
          value: losslessAudio,
          onChanged: onLosslessAudioChanged,
        ),
      ],
    );
  }
}
