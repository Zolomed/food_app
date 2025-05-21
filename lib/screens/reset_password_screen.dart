import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Отправляем запрос на сброс пароля
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailController.text.trim(),
        );

        // Показываем сообщение об успешной отправке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ссылка для сброса пароля отправлена на ${emailController.text}. Проверьте почту.',
            ),
          ),
        );

        // Возвращаемся на предыдущий экран
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        // Обрабатываем ошибки Firebase
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Произошла ошибка: ${e.message}'),
          ),
        );
      } catch (e) {
        // Обрабатываем другие ошибки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Произошла неизвестная ошибка.'),
          ),
        );
        print(e);
      }
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
                'Сброс пароля',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Пожалуйста, введите свой адрес электронной почты, чтобы запросить сброс пароля.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
              Center(
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text(
                    'Отправить новый пароль',
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
