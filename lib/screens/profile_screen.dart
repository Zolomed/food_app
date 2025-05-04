import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
//TODO сделать сохранение информации в бд
//TODO сделать отображение пароля при нажатии на глазик
//TODO реализовать правильные переходы

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController =
      TextEditingController(text: 'Иван');
  final TextEditingController phoneController =
      TextEditingController(); // Изначально пустой
  final TextEditingController emailController =
      TextEditingController(text: ''); // Почта необязательна
  bool isEditing = false;

  void toggleEditing() {
    setState(() {
      if (!isEditing) {
        if (phoneController.text.trim().isEmpty) {
          phoneController.text = '+7 ';
        }
      } else {
        if (phoneController.text.trim() == '+7') {
          phoneController.clear();
        }
      }
      isEditing = !isEditing;
    });
  }

  void saveProfile() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, введите ваше имя')),
      );
      return;
    }

    if (phoneController.text.trim().isEmpty ||
        phoneController.text.trim() == '+7') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, введите ваш номер телефона')),
      );
      return;
    }

    String phone = phoneController.text.trim();
    phone = toNumericString(phone);

    if (phone.length != 11 || !phone.startsWith('7')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите корректный номер телефона')),
      );
      return;
    }

    print('Сохранено:');
    print('Имя: ${nameController.text}');
    print('Телефон: $phone');
    print(
        'Email: ${emailController.text.isNotEmpty ? emailController.text : 'Не указан'}');

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
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset:
            true, // Позволяет экрану адаптироваться к клавиатуре
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
        body: SingleChildScrollView(
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
                  labelText: 'Введите ваше имя',
                  labelStyle: TextStyle(color: Colors.grey),
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
                  PhoneInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Введите номер телефона',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '+7 (___) ___-__-__',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'E-mail (необязательно)',
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
                  labelText: 'Введите ваш email',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
