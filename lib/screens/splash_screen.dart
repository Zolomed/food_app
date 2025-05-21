import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
          Future.microtask(() => Navigator.pushNamedAndRemoveUntil(
                context,
                '/restaurants',
                (route) => false,
              ));
        } else {
          // Пользователь не авторизован
          Future.microtask(() => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              ));
        }
        return SizedBox.shrink();
      },
    );
  }
}
