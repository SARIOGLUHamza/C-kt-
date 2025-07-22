import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:deneme/views/home_screen.dart';
import 'package:deneme/core/constants/app_constants.dart';
import 'package:deneme/controllers/simple_controller.dart';
import 'package:deneme/controllers/course_controlelr.dart';
import 'package:deneme/controllers/week_controler.dart';
import 'package:deneme/controllers/note_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(CourseController());
  Get.put(WeekController());
  Get.put(NoteController(""));
  Get.put(SimpleController());

  await Future.delayed(Duration(milliseconds: 100));
  print('Uygulama başlatılıyor...');

  runApp(const NoteVaultApp());
}

/// Ana uygulama widget'ı
class NoteVaultApp extends StatelessWidget {
  const NoteVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      locale: const Locale('tr', 'TR'),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Açık tema
  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      primaryColor: Color(AppConstants.primaryColorValue),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(AppConstants.primaryColorValue),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(AppConstants.accentColorValue),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  /// Koyu tema
  ThemeData _buildDarkTheme() {
    return ThemeData.dark(useMaterial3: true).copyWith(
      primaryColor: Color(AppConstants.primaryColorValue),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(AppConstants.primaryColorValue),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(AppConstants.accentColorValue),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
