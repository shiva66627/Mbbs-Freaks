import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationState();
  }

  _checkAuthenticationState() async {
    // Add a minimum splash duration for UX
    await Future.delayed(const Duration(seconds: 2));
    
    // Wait for Firebase to restore authentication state
    await FirebaseAuth.instance.authStateChanges().first;
    
    if (mounted) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('User is already signed in: ${user.email}');
        // User is already logged in, go directly to home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('No user signed in, going to login');
        // No user logged in, go to login page
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              "assets/LOGGOS.jpeg", // make sure logo.png is in assets folder
              height: 120,
            ),
            SizedBox(height: 20),
            
            // App title
            Text(
              "MBBSFreaks",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.purple, // same as in your screenshot
              ),
            ),
            SizedBox(height: 30),

            // Loading indicator
            CircularProgressIndicator(
              color: Colors.purple,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
