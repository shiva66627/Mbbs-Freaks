import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // 👈 Add this
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/user_content_browser.dart';
import 'screens/notes.dart';
import 'screens/pyqs.dart';
import 'screens/question_bank.dart';
import 'screens/quiz.dart';
import 'screens/admin_login_page.dart';
import 'screens/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 👇 Enable Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity, // ✅ since you registered Play Integrity
    appleProvider: AppleProvider.debug, // use .appAttest for production iOS
  );

  runApp(const EducationalApp());
}

class EducationalApp extends StatefulWidget {
  const EducationalApp({super.key});

  @override
  State<EducationalApp> createState() => _EducationalAppState();
}

class _EducationalAppState extends State<EducationalApp> {
  ThemeMode _themeMode = ThemeMode.light;

  /// Called from AdminDashboard to change theme
  void _toggleTheme(bool darkMode) {
    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Educational Content App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode, // 👈 controls whole app theme
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/content': (context) => const UserContentBrowser(),
        '/notes': (context) => const NotesPage(),
        '/pyqs': (context) => const PyqsPage(),
        '/question_bank': (context) => const QuestionBankPage(),
        '/quiz': (context) => const QuizPage(),
        '/admin_login': (context) => const AdminLoginPage(),
        '/admin_dashboard': (context) =>
            AdminDashboard(onThemeChanged: _toggleTheme), // 👈 pass callback
      },
    );
  }
}
