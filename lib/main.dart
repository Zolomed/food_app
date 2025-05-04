import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/food_selection_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/add_address_screen.dart';
//TODO сделать общую тему для всего
//TODO реализовать переходы
//TODO реализовать BottomNavigationBar
//TODO как то убрать кучу импортов
//TODO сделать динамическое отображение информации, чтоб кнопки не убегали

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
        '/verification_code': (context) =>
            VerificationCodeScreen(), //TODO сделать VerificationCodeScreen
      },
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
