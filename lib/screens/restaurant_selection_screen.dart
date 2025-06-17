import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/restaurant_list.dart';

class RestaurantSelectionScreen extends StatefulWidget {
  const RestaurantSelectionScreen({super.key});

  @override
  State<RestaurantSelectionScreen> createState() =>
      _RestaurantSelectionScreenState();
}

class _RestaurantSelectionScreenState extends State<RestaurantSelectionScreen> {
  late Future<List<Restaurant>> _futureRestaurants;
  String _searchQuery = '';
  Set<String> _favoriteRestaurantIds = {};

  @override
  void initState() {
    super.initState();
    _futureRestaurants = fetchRestaurants();
    _loadFavoriteRestaurants();
    _checkShowAllergyPrompt();
  }

  // Получение списка ресторанов с меню из Firestore
  Future<List<Restaurant>> fetchRestaurants() async {
    final restaurantsSnapshot =
        await FirebaseFirestore.instance.collection('restaurants').get();
    List<Restaurant> restaurants = [];
    for (var doc in restaurantsSnapshot.docs) {
      final menuSnapshot = await doc.reference.collection('menu').get();
      final menu = menuSnapshot.docs
          .map((item) => MenuItem.fromMap(item.id, item.data()))
          .toList();
      restaurants.add(Restaurant.fromMap(doc.id, doc.data(), menu));
    }
    return restaurants;
  }

  // Загрузка id избранных ресторанов пользователя
  Future<void> _loadFavoriteRestaurants() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      _favoriteRestaurantIds =
          Set<String>.from(doc.data()?['favoriteRestaurants'] ?? []);
    });
  }

  // Добавление или удаление ресторана из избранного
  Future<void> _toggleFavoriteRestaurant(String restaurantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List<String> favoriteRestaurants =
        List<String>.from(doc.data()?['favoriteRestaurants'] ?? []);
    if (favoriteRestaurants.contains(restaurantId)) {
      favoriteRestaurants.remove(restaurantId);
    } else {
      favoriteRestaurants.add(restaurantId);
    }
    await docRef.update({'favoriteRestaurants': favoriteRestaurants});
    await _loadFavoriteRestaurants();
  }

  // Предложение о выборе аллергий при первом входе
  Future<void> _checkShowAllergyPrompt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.data()?['showAllergyPrompt'] == true) {
      Future.delayed(Duration.zero, () => _showAllergyPromptDialog());
    }
  }

  void _showAllergyPromptDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> allAllergies = [];
    final snapshot =
        await FirebaseFirestore.instance.collection('allergies').get();
    allAllergies = snapshot.docs.map((doc) => doc['name'] as String).toList();

    List<String> selectedAllergies = [];
    bool hideAllergenFoods = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('Впервые здесь?'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Хотите указать ваши аллергии? Это поможет скрывать блюда с аллергенами или показывать предупреждение.Если что, это всегда можно будет изменить в настройках.',
                  ),
                  SizedBox(height: 16),
                  Text('Выберите аллергии:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Divider(),
                  SwitchListTile(
                    title: Text('Скрывать блюда с аллергенами'),
                    value: hideAllergenFoods,
                    onChanged: (val) {
                      setState(() {
                        hideAllergenFoods = val;
                      });
                    },
                  ),
                  if (!hideAllergenFoods)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Если не скрывать, будет отображаться предупреждение на блюдах с вашими аллергенами.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Сохраняем выбор пользователя
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'allergies': selectedAllergies,
                    'hideAllergenFoods': hideAllergenFoods,
                    'showAllergyPrompt': false,
                  });
                  Navigator.of(ctx).pop();
                  setState(() {}); // обновить экран
                },
                child: Text('Сохранить'),
              ),
              TextButton(
                onPressed: () async {
                  // Просто скрываем предложение
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'showAllergyPrompt': false,
                  });
                  Navigator.of(ctx).pop();
                },
                child: Text('Пропустить'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Выбор ресторана',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Поле поиска по ресторанам
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по ресторанам',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          // Использование виджета RestaurantList для отображения ресторанов
          Expanded(
            child: FutureBuilder<List<Restaurant>>(
              future: _futureRestaurants,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Нет доступных ресторанов'));
                }
                return RestaurantList(
                  restaurants: snapshot.data!,
                  favoriteRestaurantIds: _favoriteRestaurantIds,
                  onFavoriteTap: (id) async {
                    await _toggleFavoriteRestaurant(id);
                  },
                  searchQuery: _searchQuery,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
