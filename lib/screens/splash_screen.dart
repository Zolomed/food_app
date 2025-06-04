import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Проверяем, авторизован ли пользователь
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Показываем индикатор загрузки, пока идет проверка
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          // Если пользователь найден — переход к списку ресторанов
          Future.microtask(() => Navigator.pushNamedAndRemoveUntil(
                context,
                '/restaurants',
                (route) => false,
              ));
        } else {
          // Если пользователь не найден — переход на экран входа
          Future.microtask(() => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              ));
        }
        // Пока идет переход — возвращаем пустой виджет
        return SizedBox.shrink();
      },
    );
  }
}
