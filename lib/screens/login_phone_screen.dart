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
  String? verificationId;

  // Отправка кода подтверждения или вход по номеру телефона
  void _login() async {
    setState(() {
      errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      FirebaseAuth auth = FirebaseAuth.instance;

      if (kIsWeb) {
        // Веб: отправка кода и подтверждение
        ConfirmationResult confirmationResult =
            await auth.signInWithPhoneNumber(
                phoneController.text.trim().replaceAll(RegExp(r'[^\d+]'), ''));

        setState(() {
          isCodeSent = true;
        });

        await confirmationResult.confirm(smsCodeController.text.trim());
        Navigator.pushReplacementNamed(context, '/restaurants');
      } else {
        // Мобильное устройство: отправка кода и обработка событий
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

  // Подтверждение кода из SMS
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
              // Поле для ввода номера телефона
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
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
                // Поле для ввода кода из SMS
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
              // Отображение ошибки, если есть
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              // Кнопка отправки или подтверждения кода
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
