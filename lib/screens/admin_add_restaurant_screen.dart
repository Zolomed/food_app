import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AdminAddRestaurantScreen extends StatefulWidget {
  const AdminAddRestaurantScreen({super.key});

  @override
  State<AdminAddRestaurantScreen> createState() =>
      _AdminAddRestaurantScreenState();
}

class _AdminAddRestaurantScreenState extends State<AdminAddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final cuisineController = TextEditingController();
  File? _restaurantImageFile;

  // Для меню
  final List<Map<String, dynamic>> menuItems = [];
  final menuNameController = TextEditingController();
  final menuPriceController = TextEditingController();
  final menuCategoryController = TextEditingController();
  final menuWeightController = TextEditingController();
  final menuDescriptionController = TextEditingController();
  final menuIngredientsController = TextEditingController(); // Новый контроллер
  File? _menuImageFile;
  List<String> selectedMenuAllergens = [];

  List<String> allAllergies = [];
  bool isLoadingAllergies = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAllAllergies();
  }

  Future<void> fetchAllAllergies() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('allergies').get();
    setState(() {
      allAllergies = snapshot.docs.map((doc) => doc['name'] as String).toList();
      isLoadingAllergies = false;
    });
  }

  Future<String?> _uploadImage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _pickRestaurantImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _restaurantImageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickMenuImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _menuImageFile = File(picked.path);
      });
    }
  }

  void _addMenuItem() async {
    if (menuNameController.text.isEmpty || menuPriceController.text.isEmpty) {
      return;
    }
    setState(() => isLoading = true);

    String? imageUrl;
    if (_menuImageFile != null) {
      imageUrl = await _uploadImage(
          _menuImageFile!, 'menu/${DateTime.now().millisecondsSinceEpoch}.jpg');
    }

    menuItems.add({
      'name': menuNameController.text.trim(),
      'price': int.tryParse(menuPriceController.text.trim()) ?? 0,
      'image': imageUrl ?? '',
      'category': menuCategoryController.text.trim(),
      'weight': menuWeightController.text.trim(),
      'description': menuDescriptionController.text.trim(),
      'ingredients': menuIngredientsController.text.trim(), // Новое поле
      'allergens': selectedMenuAllergens,
    });

    menuNameController.clear();
    menuPriceController.clear();
    menuCategoryController.clear();
    menuWeightController.clear();
    menuDescriptionController.clear();
    menuIngredientsController.clear();
    selectedMenuAllergens = [];
    _menuImageFile = null;
    setState(() => isLoading = false);
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    String? imageUrl;
    if (_restaurantImageFile != null) {
      imageUrl = await _uploadImage(_restaurantImageFile!,
          'restaurants/${DateTime.now().millisecondsSinceEpoch}.jpg');
    }

    final restaurantRef =
        await FirebaseFirestore.instance.collection('restaurants').add({
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'image': imageUrl ?? '',
      'cuisine': cuisineController.text.trim(),
    });

    for (var item in menuItems) {
      await restaurantRef.collection('menu').add(item);
    }

    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ресторан добавлен!')),
    );
    nameController.clear();
    descriptionController.clear();
    cuisineController.clear();
    _restaurantImageFile = null;
    menuItems.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingAllergies) {
      return Scaffold(
        appBar: AppBar(title: Text('Добавить ресторан (админ)')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Добавить ресторан (админ)')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickRestaurantImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _restaurantImageFile != null
                            ? FileImage(_restaurantImageFile!)
                            : null,
                        child: _restaurantImageFile == null
                            ? Icon(Icons.camera_alt,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration:
                          InputDecoration(labelText: 'Название ресторана'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Введите название' : null,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: cuisineController,
                      decoration: InputDecoration(labelText: 'Тип кухни'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Введите тип кухни' : null,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Описание'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Введите описание' : null,
                    ),
                    SizedBox(height: 30),
                    Divider(),
                    Text('Меню', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...menuItems.map((item) => ListTile(
                          leading: item['image'] != null && item['image'] != ''
                              ? Image.network(item['image'],
                                  width: 40, height: 40, fit: BoxFit.cover)
                              : Icon(Icons.fastfood),
                          title: Text(item['name']),
                          subtitle: Text('${item['price']} ₽'),
                        )),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: menuNameController,
                            decoration: InputDecoration(labelText: 'Блюдо'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: menuPriceController,
                            decoration: InputDecoration(labelText: 'Цена'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: menuCategoryController,
                            decoration: InputDecoration(labelText: 'Категория'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: menuWeightController,
                            decoration: InputDecoration(
                                labelText: 'Вес (например, 260 г)'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: menuDescriptionController,
                      decoration: InputDecoration(labelText: 'Описание блюда'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: menuIngredientsController,
                      decoration:
                          InputDecoration(labelText: 'Ингредиенты блюда'),
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Аллергены блюда',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    ...allAllergies.map((allergy) => CheckboxListTile(
                          title: Text(allergy),
                          value: selectedMenuAllergens.contains(allergy),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedMenuAllergens.add(allergy);
                              } else {
                                selectedMenuAllergens.remove(allergy);
                              }
                            });
                          },
                        )),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.orange),
                          onPressed: _pickMenuImage,
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.green),
                          onPressed: _addMenuItem,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _saveRestaurant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 70, vertical: 15),
                      ),
                      child: Text('Сохранить ресторан'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
