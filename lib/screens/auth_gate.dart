import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';
import 'welcome_screen.dart';
import 'main_shell.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Widget _loading() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loading();
        }
        // Logged out
        if (!snapshot.hasData) return const WelcomeScreen();

        // Logged in: profile check karo
        return FutureBuilder<Map<String, dynamic>?>(
          future: ProfileService().loadProfile(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState != ConnectionState.done) {
              return _loading();
            }
            final data = profileSnap.data;
            if (data == null || data['profileComplete'] != true) {
              return const ProfileScreen();
            }
            if (data['quizComplete'] != true) {
              return const QuizScreen();
            }
            return const MainShell();
          },
        );
      },
    );
  }
}