import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

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

  Future<void> addToCart(Map<String, dynamic> menuItem) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc['cart'] ?? []);
    final index =
        cart.indexWhere((item) => item['menuItemId'] == menuItem['menuItemId']);
    if (index >= 0) {
      cart[index]['quantity'] += 1;
    } else {
      cart.add({...menuItem, 'quantity': 1});
    }
    await docRef.update({'cart': cart});
    _loadCart();
  }

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

  Future<void> clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'cart': []});
    _loadCart();
  }

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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      'Корзина пуста',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => Divider(height: 32),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item['image'] != null &&
                                  item['image'].toString().startsWith('http')
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove, color: Colors.black),
                                onPressed: () async {
                                  await decreaseFromCart(item);
                                },
                              ),
                              Text(
                                '${item['quantity']}',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              IconButton(
                                icon: Icon(Icons.add, color: Colors.black),
                                onPressed: () async {
                                  await addToCart(item);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cartItems.isEmpty
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Оплата успешно выполнена!')),
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
                          'Оплатить',
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
