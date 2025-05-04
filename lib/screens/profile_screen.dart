import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController =
      TextEditingController(text: 'Иван');
  final TextEditingController emailController =
      TextEditingController(text: 'primer@gmail.com');
  final TextEditingController phoneController =
      TextEditingController(); // Изначально пустой
  bool isEditing = false;

  void toggleEditing() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void saveProfile() {
    // Проверяем, что все поля заполнены
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, введите ваше имя и фамилию')),
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, введите ваш email')),
      );
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, введите ваш номер телефона')),
      );
      return;
    }

    // Получаем введенный номер телефона
    String phone = phoneController.text.trim();

    // Убираем все лишние символы, кроме цифр
    phone = toNumericString(phone);

    // Проверяем, что номер телефона не пустой
    if (phone.isNotEmpty) {
      // Если номер не начинается с 7, добавляем код страны
      if (!phone.startsWith('7')) {
        phone = '7$phone';
      }

      // Форматируем номер обратно с префиксом +7 и пробелами
      phoneController.text =
          '+7 (${phone.substring(1, 4)}) ${phone.substring(4, 7)}-${phone.substring(7, 9)}-${phone.substring(9)}';
    } else {
      // Если номер пустой, оставляем поле пустым
      phoneController.text = '';
    }

    // Здесь можно добавить логику сохранения данных (например, отправка на сервер)
    print('Сохранено:');
    print('Имя: ${nameController.text}');
    print('Email: ${emailController.text}');
    print('Телефон: ${phone.isNotEmpty ? int.tryParse(phone) : 'Не указан'}');

    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Профиль успешно сохранен!')),
    );
  }

  Future<bool> _onWillPop() async {
    if (isEditing) {
      setState(() {
        isEditing = false;
      });
      return false; // Остаемся на текущей странице
    }
    return true; // Возвращаемся на предыдущую страницу
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Профиль',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          actions: [
            if (!isEditing)
              IconButton(
                icon: Icon(Icons.edit, color: Colors.orange),
                onPressed: toggleEditing,
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          AssetImage('assets/images/avatar_placeholder.png'),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.orange,
                          child: Icon(
                            Icons.camera_alt,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      nameController.text,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isEditing)
                      TextButton(
                        onPressed: () {
                          // Логика изменения аватара
                        },
                        child: Text(
                          'Изменить аватар',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Имя',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              TextField(
                controller: nameController,
                readOnly: !isEditing,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'E-mail',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              TextField(
                controller: emailController,
                readOnly: !isEditing,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Телефон',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              TextField(
                controller: phoneController,
                readOnly: !isEditing,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  PhoneInputFormatter(
                    defaultCountryCode: 'RU', // Устанавливаем формат для России
                  ),
                ],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '+7 (___) ___-__-__',
                ),
              ),
              SizedBox(height: 20),
              if (isEditing)
                Center(
                  child: ElevatedButton(
                    onPressed: saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    ),
                    child: Text(
                      'Сохранить',
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
