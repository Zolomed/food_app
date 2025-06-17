import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'add_address_screen.dart';
import 'change_password_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  bool isLoading = true;
  List<String> selectedAllergies = [];
  bool hideAllergenFoods = true;

  File? _avatarFile;
  String? _photoUrl;

  List<String> allAllergies = [];
  bool isLoadingAllergies = true;

  List<Map<String, dynamic>> addresses = [];
  String? selectedAddressId;

  bool allergiesDropdownOpened = false;

  @override
  void initState() {
    super.initState();
    fetchAllAllergies(); // Загрузка всех возможных аллергий
    _loadUserData(); // Загрузка данных пользователя
    _loadAddresses(); // Загрузка адресов пользователя
  }

  // Получение списка всех аллергий из Firestore
  Future<void> fetchAllAllergies() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('allergies').get();
    setState(() {
      allAllergies = snapshot.docs.map((doc) => doc['name'] as String).toList();
      isLoadingAllergies = false;
    });
  }

  // Загрузка информации о пользователе
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      nameController.text = data?['name'] ?? '';
      phoneController.text = data?['phone'] ?? '';
      emailController.text = data?['email'] ?? '';
      _photoUrl = data?['photoUrl'];
      selectedAllergies = List<String>.from(data?['allergies'] ?? []);
      hideAllergenFoods = data?['hideAllergenFoods'] ?? true;
      selectedAddressId = data?['selectedAddressId'];
      setState(() {
        isLoading = false;
      });
    }
  }

  // Загрузка адресов пользователя
  Future<void> _loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List addressesRaw = doc.data()?['addresses'] ?? [];
    setState(() {
      addresses = List<Map<String, dynamic>>.from(addressesRaw);
      if (addresses.isNotEmpty && selectedAddressId == null) {
        selectedAddressId = addresses.first['id'];
      }
    });
  }

  // Сохранение изменений профиля пользователя
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? photoUrl = await _uploadAvatar(user.uid);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'photoUrl': photoUrl,
          'allergies': selectedAllergies,
          'hideAllergenFoods': hideAllergenFoods,
          'selectedAddressId': selectedAddressId,
        });
        Navigator.pop(context);
      }
    }
  }

  // Выбор аватара пользователя из галереи
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  // Загрузка аватара пользователя в Firebase Storage
  Future<String?> _uploadAvatar(String uid) async {
    if (_avatarFile == null) return _photoUrl;
    final ref =
        FirebaseStorage.instance.ref().child('avatars').child('$uid.jpg');
    await ref.putFile(_avatarFile!);
    return await ref.getDownloadURL();
  }

  // Добавление нового адреса пользователя
  Future<void> _addAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressScreen()),
    );
    if (result == true) {
      await _loadAddresses();
      setState(() {});
    }
  }

  // Удаление адреса пользователя
  Future<void> _deleteAddress(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List<Map<String, dynamic>> currentAddresses =
        List<Map<String, dynamic>>.from(doc['addresses'] ?? []);
    currentAddresses.removeWhere((a) => a['id'] == id);

    String? newSelectedId = selectedAddressId;
    if (selectedAddressId == id) {
      newSelectedId =
          currentAddresses.isNotEmpty ? currentAddresses.first['id'] : null;
    }

    await docRef.update({
      'addresses': currentAddresses,
      'selectedAddressId': newSelectedId,
    });

    setState(() {
      addresses = currentAddresses;
      selectedAddressId = newSelectedId;
    });
  }

  // Подсказка о возможности удаления адреса
  void _showDeleteAddressHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Долгое нажатие по адресу — удалить адрес'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingAllergies || isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Редактировать профиль')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final orangeUnderlineDecoration = InputDecoration(
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.orange, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.black),
    );
    return Scaffold(
      appBar: AppBar(title: Text('Редактировать профиль')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                // Аватар пользователя
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : (_photoUrl != null && _photoUrl!.isNotEmpty
                                  ? NetworkImage(_photoUrl!)
                                  : AssetImage(
                                          'assets/images/avatar_placeholder.jpg')
                                      as ImageProvider),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: _pickAvatar,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Выбор адреса доставки
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Адрес доставки',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedAddressId,
                  items: [
                    ...addresses.map((address) => DropdownMenuItem<String>(
                          value: address['id'],
                          child: GestureDetector(
                            onLongPress: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Удалить адрес?'),
                                  content: Text(
                                      'Вы действительно хотите удалить этот адрес?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('Удалить',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _deleteAddress(address['id']);
                              }
                            },
                            onTap: _showDeleteAddressHint,
                            child: Text(address['name'] ?? 'Без названия'),
                          ),
                        )),
                    DropdownMenuItem<String>(
                      value: 'add_new',
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Добавить адрес',
                              style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == 'add_new') {
                      await _addAddress();
                    } else {
                      setState(() {
                        selectedAddressId = value;
                      });
                      _showDeleteAddressHint();
                    }
                  },
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.white,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                    hintStyle: TextStyle(color: Colors.black),
                  ),
                  onTap: _showDeleteAddressHint,
                ),
                SizedBox(height: 20),
                // Имя пользователя
                TextFormField(
                  controller: nameController,
                  decoration:
                      orangeUnderlineDecoration.copyWith(labelText: 'Телефон'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Введите имя' : null,
                ),
                SizedBox(height: 20),
                // Телефон пользователя
                TextFormField(
                  controller: phoneController,
                  decoration:
                      orangeUnderlineDecoration.copyWith(labelText: 'Телефон'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Введите телефон' : null,
                ),
                SizedBox(height: 20),
                // Email пользователя
                TextFormField(
                  controller: emailController,
                  decoration:
                      orangeUnderlineDecoration.copyWith(labelText: 'Телефон'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Кнопка "Сменить пароль"
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0), // чтобы не было лишних отступов
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangePasswordScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          'Сменить пароль',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Переключатель скрытия аллергенных блюд
                SwitchListTile(
                  title: Text('Скрывать блюда с аллергенами'),
                  value: hideAllergenFoods,
                  onChanged: (val) {
                    setState(() {
                      hideAllergenFoods = val;
                    });
                  },
                ),
                SizedBox(height: 20),
                // Выбор аллергий пользователя
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Мои аллергии',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      allergiesDropdownOpened = !allergiesDropdownOpened;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedAllergies.isEmpty
                                ? 'Выберите аллергии'
                                : selectedAllergies.join(', '),
                            style: TextStyle(
                              color: selectedAllergies.isEmpty
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                        Icon(
                          allergiesDropdownOpened
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                if (allergiesDropdownOpened)
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: allAllergies.map((allergy) {
                        return CheckboxListTile(
                          title: Text(allergy),
                          value: selectedAllergies.contains(allergy),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedAllergies.add(allergy);
                              } else {
                                selectedAllergies.remove(allergy);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      // Кнопка сохранения изменений профиля
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text('Сохранить'),
          ),
        ),
      ),
    );
  }
}
