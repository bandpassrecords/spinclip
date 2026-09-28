import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/providers.dart';
import '../ui/screens/home_screen.dart';

class SpinclipApp extends ConsumerWidget {
  const SpinclipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Spinclip',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF33CCFF),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const HomeScreen(),
    );
  }
}
