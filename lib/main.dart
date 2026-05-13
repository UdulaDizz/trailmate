import 'firebase_options.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database/database_helper.dart';
import 'services/sync_service.dart';
import 'models/app_colors.dart';
import 'views/splash_screen.dart';
import 'views/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // UPDATED: Tell Firebase to use the keys we just downloaded
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await DatabaseHelper.instance.database;
  SyncService.instance.startListening();

  runApp(const TrailMateApp());
}

class TrailMateApp extends StatelessWidget {
  const TrailMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrailMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
      ),
      // Automatically skips login if the user is already signed in securely via Firebase!
      home: FirebaseAuth.instance.currentUser == null 
          ? const SplashScreen() 
          : const MainNavigation(),
    );
  }
}