import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sarthi_pilot/firebase_options.dart';
import 'package:sarthi_pilot/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const SarthiPilotApp());
}

class SarthiPilotApp extends StatelessWidget {
  const SarthiPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IIT Ropar Transit — Driver Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          primary: const Color(0xFF059669),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
