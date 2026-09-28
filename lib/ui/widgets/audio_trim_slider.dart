import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// A single range slider (two handles) spanning the full track, so picking
/// the excerpt to use is "drag the left handle to the start, the right
/// handle to the end" rather than separate start/duration controls.
class AudioTrimSlider extends StatelessWidget {
  final bool fullDuration;
  final ValueChanged<bool> onFullDurationChanged;
  final double trimStartSeconds;
  final double? trimDurationSeconds;
  final double? probedDurationSeconds;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onDurationChanged;

  const AudioTrimSlider({
    super.key,
    required this.fullDuration,
    required this.onFullDurationChanged,
    required this.trimStartSeconds,
    required this.trimDurationSeconds,
    required this.probedDurationSeconds,
    required this.onStartChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxDuration = probedDurationSeconds ?? 300;
    final effectiveDuration =
        trimDurationSeconds ??
        (maxDuration - trimStartSeconds).clamp(1, maxDuration);
    final start = trimStartSeconds.clamp(0, maxDuration).toDouble();
    final end = (start + effectiveDuration)
        .clamp(start, maxDuration)
        .toDouble();

    String fmt(double seconds) {
      final m = (seconds ~/ 60).toString().padLeft(2, '0');
      final s = (seconds.round() % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.fullDuration),
          subtitle: Text(l10n.fullDurationSubtitle),
          value: fullDuration,
          onChanged: onFullDurationChanged,
        ),
        if (!fullDuration) ...[
          if (probedDurationSeconds == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.probingTrackLength,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Text(
            l10n.trimRangeLabel(
              fmt(start),
              fmt(end),
              effectiveDuration.toStringAsFixed(1),
            ),
          ),
          RangeSlider(
            values: RangeValues(start, end),
            min: 0,
            max: maxDuration,
            labels: RangeLabels(fmt(start), fmt(end)),
            onChanged: (values) {
              onStartChanged(values.start);
              onDurationChanged(
                (values.end - values.start).clamp(0.1, maxDuration),
              );
            },
          ),
        ],
      ],
    );
  }
}
