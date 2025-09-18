import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/repositories/auth_repository_lokin.dart';
import 'data/services/preference_service_lokin.dart';
import 'lokin_app.dart';

// Import untuk debugging (bisa dihapus di production)
// import 'network_debugger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data untuk DateFormatting
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);

  // Initialize services
  await _initializeServices();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Uncomment untuk debugging network (hanya untuk testing)
  // print('Running network test...');
  // await ApiTester.runFullTest();

  runApp(const LokinApp());
}

Future<void> _initializeServices() async {
  try {
    print('Initializing services...');

    // Initialize SharedPreferences
    await PreferenceService().init();
    print('SharedPreferences initialized');

    // Initialize Authentication
    await AuthRepository().initAuth();
    print('Authentication initialized');

    print('All services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
    // Don't throw error, let app continue
  }
}
