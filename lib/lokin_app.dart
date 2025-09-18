import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/splash/splash_screen_lokin.dart';
import 'theme/app_theme_lokin.dart';

class LokinApp extends StatelessWidget {
  const LokinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LokinID - PPKDJP',
      debugShowCheckedModeBanner: false,
      theme: AppThemeLokin.lightTheme,
      darkTheme: AppThemeLokin.darkTheme,
      themeMode: ThemeMode.system,

      // Localization support
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian
        Locale('en', 'US'), // English
      ],
      locale: const Locale('id', 'ID'), // Default to Indonesian

      home: const SplashScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0), // Prevent system font scaling
          ),
          child: child!,
        );
      },
    );
  }
}
