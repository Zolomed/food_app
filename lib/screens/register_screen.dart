import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

//TODO сделать отображение пароля при нажатии на глазик
//TODO сделать проверку на русский в пароле

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController =
      TextEditingController(text: '+7');
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Выполняем регистрацию через Firebase
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Если регистрация успешна, перенаправляем на экран ресторанов
        Navigator.pushReplacementNamed(context, '/restaurants');
        print('User registered: ${credential.user?.uid}');
        print('User registered: ${credential.user?.email}');
      } on FirebaseAuthException catch (e) {
        // Обрабатываем ошибки Firebase
        if (e.code == 'weak-password') {
          setState(() {
            errorMessage = 'Пароль слишком слабый.';
          });
        } else if (e.code == 'email-already-in-use') {
          setState(() {
            errorMessage = 'Аккаунт с таким email уже существует.';
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Регистрация',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите ваше имя';
                  }
                  return null;
                },
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
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  PhoneInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '+7 (___) ___-__-__',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  final phoneRegex =
                      RegExp(r'^\+7 \(\d{3}\) \d{3}-\d{2}-\d{2}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Введите корректный номер телефона';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: Icon(Icons.visibility),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.length < 6) {
                    return 'Пароль должен быть не менее 6 символов';
                  }
                  if (RegExp(r'[а-яА-ЯёЁ]').hasMatch(value)) {
                    return 'Пароль не должен содержать русские буквы';
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
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  ),
                  child: Text(
                    'Регистрация',
                    style: TextStyle(fontSize: 18),
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
