import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;
  bool _isPasswordVisible = false; // Состояние для управления видимостью пароля

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] != null) {
      emailController.text = args['email'];
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Проверяем, подтвержден ли email
        if (credential.user != null && !credential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            errorMessage = 'Пожалуйста, подтвердите ваш email перед входом.';
          });
          return;
        }

        // Если вход успешен и email подтвержден, перенаправляем на экран ресторанов
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/restaurants',
          (route) => false,
        );

        print('User logged in: ${credential.user?.email}');
      } on FirebaseAuthException catch (e) {
        // Обрабатываем ошибки Firebase
        if (e.code == 'user-not-found') {
          setState(() {
            errorMessage = 'Пользователь с таким email не найден.';
          });
        } else if (e.code == 'wrong-password') {
          setState(() {
            errorMessage = 'Неверный пароль.';
          });
        } else if (e.code == 'invalid-credential' ||
            e.code == 'invalid-login-credentials') {
          setState(() {
            errorMessage = 'Неверный email или пароль.';
          });
        } else {
          setState(() {
            errorMessage = 'Произошла ошибка: ${e.message}';
          });
        }
      } catch (e) {
        // Обрабатываем другие ошибки
        setState(() {
          errorMessage = 'Произошла неизвестная ошибка.';
        });
        print(e);
      }
    } else {
      setState(() {
        errorMessage = 'Пожалуйста, исправьте ошибки выше.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Позволяет экрану адаптироваться к клавиатуре
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Убираем кнопку "Назад"
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Вход',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: !_isPasswordVisible, // Управляем видимостью пароля
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible =
                            !_isPasswordVisible; // Переключаем состояние
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.length < 6) {
                    return 'Пароль должен быть не менее 6 символов';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/reset_password');
                  },
                  child: Text(
                    'Забыли пароль?',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  ),
                  child: Text(
                    'Вход',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    'Нет аккаунта? Регистрация',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
