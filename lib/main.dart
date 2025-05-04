import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/profile': (context) => ProfileScreen(),
        '/food_selection': (context) => FoodSelectionScreen(),
        '/add_address': (context) => AddAddressScreen(),
        '/payment': (context) => PaymentScreen(),
        '/reset_password': (context) => ResetPasswordScreen(),
        '/verification_code': (context) => VerificationCodeScreen(),
      },
    );
  }
}

class FoodSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Выбор еды')),
      body: Center(child: Text('Экран выбора еды')),
    );
  }
}

class AddAddressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить адрес')),
      body: Center(child: Text('Экран добавления адреса')),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Оплата')),
      body: Center(child: Text('Экран оплаты')),
    );
  }
}

class ResetPasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Сброс пароля')),
      body: Center(child: Text('Экран сброса пароля')),
    );
  }
}

class VerificationCodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Код подтверждения')),
      body: Center(child: Text('Экран ввода кода подтверждения')),
    );
  }
}
