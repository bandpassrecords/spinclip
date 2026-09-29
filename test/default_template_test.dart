import 'package:flutter_test/flutter_test.dart';
import 'package:spinclip/models/render_settings.dart';
import 'package:spinclip/models/visualizer_placement.dart';
import 'package:spinclip/models/visualizer_style.dart';
import 'package:spinclip/state/providers.dart';

void main() {
  test('new projects start with the review round 1 pick (#04)', () {
    const draft = DraftSettings();
    expect(draft.style, VisualizerStyle.bars);
    expect(draft.placement, VisualizerPlacement.bottomBand);
    expect(draft.visualizerBarCount, 48);
    expect(draft.visualizerSmoothness, 0);
    expect(draft.visualizerSensitivity, 1.0);
    expect(draft.visualizerColorHex, '0x33CCFF');

    // The CLI/test-facing RenderSettings defaults match.
    const settings = RenderSettings(imagePath: '', audioPath: '');
    expect(settings.visualizerBarCount, 48);
    expect(settings.visualizerSmoothness, 0);
  });

  test('the built-in default template carries the default look', () {
    final template = builtInTemplates.single;
    expect(template.builtIn, isTrue);
    expect(template.name, builtInDefaultTemplateName);
    expect(template.style, VisualizerStyle.bars);
    expect(template.visualizerBarCount, 48);
    expect(template.visualizerSmoothness, 0);
    // Never written to the user's template file.
    expect(template.toJson().containsKey('builtIn'), isFalse);
  });
}
