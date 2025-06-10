import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();
  String? passwordChangeError;
  bool isLoading = false;

  // Состояния для отображения/скрытия паролей
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  Future<void> _changePassword() async {
    setState(() {
      passwordChangeError = null;
      isLoading = true;
    });
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmNewPassword = confirmNewPasswordController.text.trim();

    // Проверки аналогичны регистрации
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmNewPassword.isEmpty) {
      setState(() {
        passwordChangeError = 'Пожалуйста, заполните все поля.';
        isLoading = false;
      });
      return;
    }
    if (newPassword.length < 6) {
      setState(() {
        passwordChangeError = 'Пароль должен быть не менее 6 символов';
        isLoading = false;
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?~]+$')
        .hasMatch(newPassword)) {
      setState(() {
        passwordChangeError =
            'Введите английские буквы, цифры и специальные символы';
        isLoading = false;
      });
      return;
    }
    if (newPassword != confirmNewPassword) {
      setState(() {
        passwordChangeError = 'Пароли не совпадают';
        isLoading = false;
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        setState(() {
          passwordChangeError = 'Пользователь не найден';
          isLoading = false;
        });
        return;
      }
      // Реаутентификация пользователя
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      setState(() {
        passwordChangeError = null;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароль успешно изменён')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          // Обработка ошибки некорректного текущего пароля или истёкшего токена
          passwordChangeError = 'Старый пароль введён неверно';
        } else if (e.code == 'too-many-requests') {
          passwordChangeError = 'Слишком много попыток. Попробуйте позже.';
        } else {
          passwordChangeError = 'Ошибка: ${e.message}';
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        passwordChangeError = 'Не удалось сменить пароль';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Смена пароля')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            TextFormField(
              controller: currentPasswordController,
              obscureText: !showCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Текущий пароль',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    showCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showCurrentPassword = !showCurrentPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: newPasswordController,
              obscureText: !showNewPassword,
              decoration: InputDecoration(
                labelText: 'Новый пароль',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    showNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showNewPassword = !showNewPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: confirmNewPasswordController,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Подтвердите новый пароль',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showConfirmPassword = !showConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            if (passwordChangeError != null)
              Text(
                passwordChangeError!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Сменить пароль',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
