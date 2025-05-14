import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          // Пользователь авторизован
          Future.microtask(
              () => Navigator.pushReplacementNamed(context, '/restaurants'));
        } else {
          // Пользователь не авторизован
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
        }
        return SizedBox.shrink();
      },
    );
  }
}
