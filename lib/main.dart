import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CareerMateApp());
}
class CareerMateApp extends StatelessWidget {
  const CareerMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Career Mate',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const WelcomeScreen(),
    );
  }
}
