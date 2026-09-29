import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/parts_provider.dart';
import 'providers/language_provider.dart';
import 'screens/main_nav_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: For Android/iOS native setup, make sure google-services.json / GoogleService-Info.plist are placed in android/app and ios/Runner
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase init warning (proceeding): $e');
  }

  runApp(const AutoPartsIndiaApp());
}

class AutoPartsIndiaApp extends StatelessWidget {
  const AutoPartsIndiaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => PartsProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        title: 'Auto Parts India',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.background,
          ),
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
