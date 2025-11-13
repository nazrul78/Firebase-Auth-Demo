import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_demo/home_screen.dart';
import 'package:firebase_auth_demo/login_screen.dart';
import 'package:flutter/material.dart';

class WrapperScreen extends StatefulWidget {
  const WrapperScreen({super.key});

  @override
  State<WrapperScreen> createState() => _WrapperScreenState();
}

class _WrapperScreenState extends State<WrapperScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Loading
        }
        if (snapshot.hasData) {
          return HomeScreen(); // User is logged in
        }
        return LoginScreen(); // User is not logged in
      },
    );
  }
}
