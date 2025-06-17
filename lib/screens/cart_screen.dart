import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  // Для аллергий пользователя
  List<String> userAllergies = [];
  bool hideAllergenFoods = true;

  @override
  void initState() {
    super.initState();
    _loadCart(); // Загрузка корзины при инициализации экрана
    _loadUserAllergies(); // Загрузка аллергий пользователя
  }

  // Получение корзины пользователя из Firestore
  Future<void> _loadCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      cartItems = List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
      isLoading = false;
    });
  }

  // Загрузка аллергий пользователя и настройки скрытия аллергенных блюд
  Future<void> _loadUserAllergies() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      userAllergies = List<String>.from(doc.data()?['allergies'] ?? []);
      hideAllergenFoods = doc.data()?['hideAllergenFoods'] ?? true;
    });
  }

  // Получение аллергенов блюда из Firestore
  Future<List<String>> _getMenuItemAllergens(
      String restaurantId, String menuItemId) async {
    final menuDoc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .doc(menuItemId)
        .get();
    return List<String>.from(menuDoc.data()?['allergens'] ?? []);
  }

  // Подсчёт общего количества блюд в корзине
  int get totalCount =>
      cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));

  // Добавление блюда в корзину (или увеличение количества)
  Future<void> addToCart(Map<String, dynamic> menuItem) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc['cart'] ?? []);
    final index =
        cart.indexWhere((item) => item['menuItemId'] == menuItem['menuItemId']);

    final String currentRestaurantId = menuItem['restaurantId'] ?? '';
    if (cart.isNotEmpty) {
      final String cartRestaurantId = cart.first['restaurantId'] ?? '';
      // Проверка: можно заказывать только из одного ресторана
      if (cartRestaurantId != currentRestaurantId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Можно заказывать только из одного ресторана! Очистьте корзину для нового заказа.')),
        );
        return;
      }
    }

    int totalCount =
        cart.fold<int>(0, (sum, i) => sum + (i['quantity'] as int));
    // Проверка на максимальное количество блюд
    if (totalCount >= 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Максимум 30 блюд в заказе!')),
      );
      return;
    }

    if (index >= 0) {
      cart[index]['quantity'] += 1;
    } else {
      cart.add({...menuItem, 'quantity': 1});
    }
    await docRef.update({'cart': cart});
    _loadCart();
  }

  // Уменьшение количества блюда или удаление из корзины
  Future<void> decreaseFromCart(Map<String, dynamic> menuItem) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc['cart'] ?? []);
    final index =
        cart.indexWhere((item) => item['menuItemId'] == menuItem['menuItemId']);
    if (index >= 0) {
      if (cart[index]['quantity'] > 1) {
        cart[index]['quantity'] -= 1;
      } else {
        cart.removeAt(index);
      }
      await docRef.update({'cart': cart});
      _loadCart();
    }
  }

  // Очистка всей корзины пользователя
  Future<void> clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'cart': []});
    _loadCart();
  }

  // Подсчёт итоговой суммы заказа
  double get totalPrice {
    double total = 0;
    for (var item in cartItems) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Корзина',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Очистить корзину',
              onPressed: () async {
                await clearCart();
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              // Если корзина пуста — показать сообщение
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      'Корзина пуста',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              // Список товаров в корзине
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => Divider(height: 32),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return FutureBuilder<List<String>>(
                      future: _getMenuItemAllergens(
                          item['restaurantId'], item['menuItemId']),
                      builder: (context, snapshot) {
                        final allergens = snapshot.data ?? [];
                        final containsAllergen =
                            allergens.any((a) => userAllergies.contains(a));
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Картинка блюда
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item['image'] != null &&
                                      item['image']
                                          .toString()
                                          .startsWith('http')
                                  ? Image.network(
                                      item['image'],
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.asset(
                                      item['image'] ?? '',
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                            SizedBox(width: 14),
                            // Название и параметры блюда
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // --- Предупреждение об аллергенах ---
                                  if (containsAllergen)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning,
                                              color: Colors.red, size: 16),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Содержит ваш аллерген',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(height: 6),
                                  Text(
                                    '${item['price'].toStringAsFixed(2)}₽ · ${item['weight'] ?? ''} г',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            // Кнопки для изменения количества блюда
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon:
                                        Icon(Icons.remove, color: Colors.black),
                                    onPressed: () async {
                                      await decreaseFromCart(item);
                                    },
                                  ),
                                  Text(
                                    '${item['quantity']}',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add, color: Colors.black),
                                    onPressed: totalCount >= 30
                                        ? null
                                        : () async {
                                            await addToCart(item);
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
      // Нижняя панель с итоговой суммой и кнопкой перехода к оформлению заказа
      bottomNavigationBar: cartItems.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Итого:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${(totalPrice).toStringAsFixed(2)} р.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    if (totalCount >= 30)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Максимум 30 блюд в заказе',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Переход к оформлению заказа
                        onPressed: cartItems.isEmpty
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CheckoutScreen()),
                                );
                                if (result == true) {
                                  await _loadCart();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          'Далее',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
