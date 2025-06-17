import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/food_selection_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/add_address_screen.dart';
import 'screens/restaurant_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_add_restaurant_screen.dart';
import 'screens/edit_profile_screen.dart';

//TODO как то убрать кучу импортов
//TODO реализовать рейтинг

void main() async {
  // Инициализация Flutter и Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Для DevicePreview (отладка на разных устройствах)
  // runApp(
  //   DevicePreview(
  //     enabled: true,
  //     builder: (context) => MyApp(),
  //   ),
  // );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // useInheritedMediaQuery: true,
      // builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'Living with food',
      // Основная тема приложения
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        scaffoldBackgroundColor: Colors.white,
        // Тема приложения
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          surfaceTintColor: Colors.white,
          shadowColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        // Тема переключателя
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.orange,
          ),
          trackColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
                ? Colors.orange
                : Colors.white,
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
            (states) => Colors.orange,
          ),
        ),
        // Тема чекбокса
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
                ? Colors.orange
                : Colors.white,
          ),
          checkColor: WidgetStateProperty.all(Colors.white),
        ),
        // Тема ввода текста
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Colors.orange, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          labelStyle: TextStyle(color: Colors.grey),
          floatingLabelStyle: TextStyle(color: Colors.black),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.orange,
          selectionHandleColor: Colors.orange,
          selectionColor: Colors.orange.withOpacity(0.3),
        ),
        // Тема прогресс-индикаторов
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.orange,
          circularTrackColor: Colors.orange.withOpacity(0.2),
          linearTrackColor: Colors.orange.withOpacity(0.2),
        ),
      ),
      // Начальный маршрут
      initialRoute: '/splash',
      // Маршруты приложения
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
        '/admin': (context) => AdminAddRestaurantScreen(),
      },
    );
  }
}
