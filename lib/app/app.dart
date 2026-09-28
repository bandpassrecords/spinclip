import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/screens/home_screen.dart';

class SpinclipApp extends StatelessWidget {
  const SpinclipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spinclip',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF33CCFF), useMaterial3: true, brightness: Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
