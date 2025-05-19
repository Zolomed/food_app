import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_app/screens/edit_profile_screen.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/food_selection_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/add_address_screen.dart';
import 'screens/restaurant_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';

//TODO сделать общую тему для всего
//TODO как то убрать кучу импортов
//TODO сделать динамическое отображение информации, чтоб кнопки не убегали
//TODO сделать экран избранного для еды и ресторанов

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/food_selection': (context) => FoodSelectionScreen(),
        '/add_address': (context) => AddAddressScreen(),
        '/reset_password': (context) => ResetPasswordScreen(),
        '/restaurant': (context) => RestaurantScreen(),
        '/restaurants': (context) => MainScreen(initialIndex: 0),
        '/payment': (context) => MainScreen(initialIndex: 1),
        '/profile': (context) => MainScreen(initialIndex: 2),
        '/edit_profile': (context) => EditProfileScreen(),
      },
    );
  }
}
