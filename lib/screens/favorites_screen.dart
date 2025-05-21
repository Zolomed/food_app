import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favoriteItems = [];
  Map<String, int> cartQuantities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadCartQuantities();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List<String> favoriteIds =
        List<String>.from(doc.data()?['favorites'] ?? []);
    List<Map<String, dynamic>> items = [];
    // Получаем блюда по id из всех ресторанов
    final restaurantsSnapshot =
        await FirebaseFirestore.instance.collection('restaurants').get();
    for (final restaurantDoc in restaurantsSnapshot.docs) {
      final menuSnapshot =
          await restaurantDoc.reference.collection('menu').get();
      for (final menuItemDoc in menuSnapshot.docs) {
        if (favoriteIds.contains(menuItemDoc.id)) {
          final data = menuItemDoc.data();
          data['menuItemId'] = menuItemDoc.id;
          data['restaurantId'] = restaurantDoc.id;
          items.add(data);
        }
      }
    }
    setState(() {
      favoriteItems = items;
      isLoading = false;
    });
  }

  Future<void> _loadCartQuantities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List cart =
        List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final Map<String, int> map = {};
    for (var item in cart) {
      map[item['menuItemId']] = item['quantity'];
    }
    setState(() {
      cartQuantities = map;
    });
  }

  Future<void> toggleFavorite(String menuItemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List favorites = List<String>.from(doc.data()?['favorites'] ?? []);
    if (favorites.contains(menuItemId)) {
      favorites.remove(menuItemId);
    } else {
      favorites.add(menuItemId);
    }
    await docRef.update({'favorites': favorites});
    _loadFavorites();
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final index = cart.indexWhere((i) => i['menuItemId'] == item['menuItemId']);
    if (index >= 0) {
      cart[index]['quantity'] += 1;
    } else {
      cart.add({
        'menuItemId': item['menuItemId'],
        'name': item['name'],
        'price': item['price'],
        'image': item['image'],
        'weight': item['weight'],
        'quantity': 1,
      });
    }
    await docRef.update({'cart': cart});
    await _loadCartQuantities();
  }

  Future<void> removeFromCart(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final index = cart.indexWhere((i) => i['menuItemId'] == item['menuItemId']);
    if (index >= 0) {
      if (cart[index]['quantity'] > 1) {
        cart[index]['quantity'] -= 1;
      } else {
        cart.removeAt(index);
      }
      await docRef.update({'cart': cart});
      await _loadCartQuantities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Избранное',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favoriteItems.isEmpty
              ? Center(
                  child: Text(
                    'Избранных блюд пока нет',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.60,
                  ),
                  itemCount: favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = favoriteItems[index];
                    final quantity = cartQuantities[item['menuItemId']] ?? 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F7F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Картинка + сердечко
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 12, right: 12, top: 12, bottom: 0),
                            child: Stack(
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: item['image'] != null &&
                                            item['image']
                                                .toString()
                                                .startsWith('http')
                                        ? Image.network(
                                            item['image'],
                                            height: 110,
                                            fit: BoxFit.contain,
                                          )
                                        : Image.asset(
                                            item['image'] ?? '',
                                            height: 110,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () async {
                                      await toggleFavorite(item['menuItemId']);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.85),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item['price'].toStringAsFixed(2)}₽',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              item['name'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              [
                                if (item['weight'] != null)
                                  '${item['weight']} г'
                              ].join(' · '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(child: SizedBox()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: quantity > 0
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed: () async {
                                          await removeFromCart(item);
                                          setState(() {});
                                        },
                                      ),
                                      Text(
                                        '$quantity',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline),
                                        onPressed: () async {
                                          await addToCart(item);
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await addToCart(item);
                                        setState(() {});
                                      },
                                      icon:
                                          Icon(Icons.add, color: Colors.black),
                                      label: Text(
                                        'Добавить',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        side: BorderSide(
                                            color: Colors.black12, width: 1),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
