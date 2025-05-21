import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  _LoginPhoneScreenState createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;
  bool isCodeSent = false;
  bool isVerifyCode = false;
  String? verificationId; // Для хранения verificationId

  void _login() async {
    setState(() {
      errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      FirebaseAuth auth = FirebaseAuth.instance;

      if (kIsWeb) {
        ConfirmationResult confirmationResult =
            await auth.signInWithPhoneNumber(
                phoneController.text.trim().replaceAll(RegExp(r'[^\d+]'), ''));

        setState(() {
          isCodeSent = true;
        });

        await confirmationResult.confirm(smsCodeController.text.trim());
        Navigator.pushReplacementNamed(context, '/restaurants');
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber:
              phoneController.text.trim().replaceAll(RegExp(r'[^\d+]'), ''),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await auth.signInWithCredential(credential);
            Navigator.pushReplacementNamed(context, '/restaurants');
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() {
              errorMessage = 'Ошибка: ${e.message}';
            });
          },
          codeSent: (String verificationId, int? resendToken) async {
            setState(() {
              this.verificationId = verificationId;
              isCodeSent = true;
              isVerifyCode = true;
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    }
  }

  void _verifyCode() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    if (_formKey.currentState!.validate()) {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId!,
          smsCode: smsCodeController.text.trim());

      await auth.signInWithCredential(credential);
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
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  PhoneInputFormatter()
                ], // Форматирование номера
                decoration: InputDecoration(
                  labelText: 'Номер телефона',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
              if (isCodeSent) ...[
                SizedBox(height: 20),
                TextFormField(
                  controller: smsCodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Код из SMS',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите код из SMS';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 10),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: isVerifyCode ? _verifyCode : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 70, vertical: 15),
                  ),
                  child: Text(
                    isCodeSent ? 'Подтвердить код' : 'Отправить код',
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
