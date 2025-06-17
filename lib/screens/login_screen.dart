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
  bool _isPasswordVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Автозаполнение email, если передан через аргументы
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] != null) {
      emailController.text = args['email'];
      // Показываем уведомление, если email пришёл после регистрации
      Future.delayed(const Duration(milliseconds: 300), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'На вашу почту отправлено письмо. Подтвердите аккаунт по ссылке из письма.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
  }

  // Вход пользователя по email и паролю
  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Проверка подтверждения email
        if (credential.user != null && !credential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            errorMessage = 'Пожалуйста, подтвердите ваш email перед входом.';
          });
          return;
        }

        // Переход к списку ресторанов после успешного входа
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/restaurants',
          (route) => false,
        );

        print('User logged in: ${credential.user?.email}');
      } on FirebaseAuthException catch (e) {
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок экрана
              Text(
                'Вход',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              // Поле для ввода email
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
              // Поле для ввода пароля
              TextFormField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
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
                        _isPasswordVisible = !_isPasswordVisible;
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
              // Отображение ошибки, если есть
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              // Кнопка "Забыли пароль?"
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
              // Кнопка входа
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
              // Ссылка на регистрацию
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
