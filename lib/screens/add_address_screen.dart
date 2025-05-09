import 'package:flutter/material.dart';

//TODO реализовать правильные переходы
//TODO упростить ввод адреса
//TODO сделать подсказки при вводе адреса

class AddAddressScreen extends StatefulWidget {
  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController cityController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController houseNumberController = TextEditingController();
  final TextEditingController apartmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      // Логика сохранения адреса
      print('Город: ${cityController.text}');
      print('Улица: ${streetController.text}');
      print('Номер дома: ${houseNumberController.text}');
      print('Квартира: ${apartmentController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Адрес успешно сохранен!')),
      );
      Navigator.pop(context); // Возвращаемся на предыдущий экран
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
        title: Text(
          'Добавить адрес',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Введите адрес доставки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'Город',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите город';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: streetController,
                decoration: InputDecoration(
                  labelText: 'Улица',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите улицу';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: houseNumberController,
                decoration: InputDecoration(
                  labelText: 'Номер дома',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер дома';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: apartmentController,
                decoration: InputDecoration(
                  labelText: 'Квартира (необязательно)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  ),
                  child: Text(
                    'Сохранить адрес',
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
