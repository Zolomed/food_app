import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  // Контроллеры для полей ввода адреса
  final TextEditingController cityController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController houseNumberController = TextEditingController();
  final TextEditingController apartmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController addressNameController = TextEditingController();

  bool isLocating =
      false; // Флаг для отображения процесса определения геолокации

  // Заполнение полей адреса по текущей геолокации пользователя
  Future<void> _fillAddressFromLocation() async {
    setState(() {
      isLocating = true;
    });
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Разрешите доступ к геолокации')),
        );
        setState(() {
          isLocating = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        cityController.text = place.locality ?? '';
        streetController.text = place.street ?? '';
        houseNumberController.text = place.subThoroughfare ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось определить адрес')),
      );
    }
    setState(() {
      isLocating = false;
    });
  }

  // Сохранение нового адреса пользователя в Firestore
  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final addressId = DateTime.now().millisecondsSinceEpoch.toString();
      final newAddress = {
        'id': addressId,
        'name': addressNameController.text.trim(),
        'city': cityController.text.trim(),
        'street': streetController.text.trim(),
        'house': houseNumberController.text.trim(),
        'apartment': apartmentController.text.trim(),
      };

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        final List addresses = List<Map<String, dynamic>>.from(
            snapshot.data()?['addresses'] ?? []);
        addresses.add(newAddress);
        transaction.update(userDoc, {
          'addresses': addresses,
          'selectedAddressId': addressId,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Адрес успешно сохранен!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              SizedBox(height: 24),
              // Поле для названия адреса (например, "Дом" или "Работа")
              TextFormField(
                controller: addressNameController,
                decoration: InputDecoration(
                  labelText: 'Название адреса',
                  hintText: 'Например, Дом или Работа',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: addressNameController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => addressNameController.clear(),
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название адреса';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Поле для города
              TextFormField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'Город',
                  hintText: 'Например, Москва',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: cityController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => cityController.clear(),
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите город';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Поле для улицы
              TextFormField(
                controller: streetController,
                decoration: InputDecoration(
                  labelText: 'Улица',
                  hintText: 'Например, Ленина',
                  prefixIcon: Icon(Icons.map),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: streetController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => streetController.clear(),
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите улицу';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Поле для номера дома
              TextFormField(
                controller: houseNumberController,
                decoration: InputDecoration(
                  labelText: 'Номер дома',
                  hintText: 'Например, 10',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: houseNumberController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => houseNumberController.clear(),
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер дома';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Поле для квартиры (необязательно)
              TextFormField(
                controller: apartmentController,
                decoration: InputDecoration(
                  labelText: 'Квартира (необязательно)',
                  hintText: 'Например, 12',
                  prefixIcon: Icon(Icons.door_front_door),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: apartmentController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => apartmentController.clear(),
                        )
                      : null,
                ),
              ),
              SizedBox(height: 24),
              // Кнопка для сохранения адреса
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Center(
                      child: Text(
                        'Сохранить адрес',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Кнопка для автозаполнения адреса по геолокации
              Center(
                child: ElevatedButton.icon(
                  onPressed: isLocating ? null : _fillAddressFromLocation,
                  icon: Icon(Icons.my_location),
                  label: Text(isLocating
                      ? 'Определение...'
                      : 'Заполнить по геолокации'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
