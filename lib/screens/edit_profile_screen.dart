import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

//TODO сделать потверждение пароля после смены
//TODO сделать уведомление о смене пароля

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

  @override
  void initState() {
    super.initState();
    fetchAllAllergies();
    _loadUserData();
  }

  Future<void> fetchAllAllergies() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('allergies').get();
    setState(() {
      allAllergies = snapshot.docs.map((doc) => doc['name'] as String).toList();
      isLoadingAllergies = false;
    });
  }

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
      setState(() {
        isLoading = false;
      });
    }
  }

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

  Future<String?> _uploadAvatar(String uid) async {
    if (_avatarFile == null) return _photoUrl;
    final ref =
        FirebaseStorage.instance.ref().child('avatars').child('$uid.jpg');
    await ref.putFile(_avatarFile!);
    return await ref.getDownloadURL();
  }

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
        });
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingAllergies || isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Редактировать профиль')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
                                          'assets/images/avatar_placeholder.png')
                                      as ImageProvider),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickAvatar,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Имя'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Введите имя' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Телефон'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Введите телефон' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'E-mail'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Мои аллергии',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ...allAllergies.map((allergy) => CheckboxListTile(
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
                    )),
              ],
            ),
          ),
        ),
      ),
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
