import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'screens/age_selection_screen.dart';
import 'screens/game_screen.dart';
import 'services/locale_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Suppress yellow-black zebra stripe overflow warnings across all devices
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox.shrink();
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await StorageService.instance.init();
  LocaleService.instance.init();
  runApp(const AlgoKidsApp());
}

class AlgoKidsApp extends StatelessWidget {
  const AlgoKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final Widget initialHome = storage.hasSelectedAge
        ? GameScreen(initialAgeMode: storage.ageMode)
        : const AgeSelectionScreen();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialHome,
    );
  }
}
