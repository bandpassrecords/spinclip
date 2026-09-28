// Basic smoke test: the app boots and shows its home screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spinclip/app/app.dart';

void main() {
  testWidgets('App boots and shows the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpinclipApp()));

    expect(find.text('Spinclip'), findsOneWidget);
    // The wizard opens on the first page (Release type).
    expect(find.textContaining('Release type'), findsOneWidget);
    expect(find.text('Single song'), findsOneWidget);
  });
}
