import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//TODO переименовать в корзину
//TODO сделать возможность поменять адрес
//TODO реализовать правильные переходы

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

  Future<void> removeFromCart(String menuItemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc['cart'] ?? []);
    cart.removeWhere((item) => item['menuItemId'] == menuItemId);
    await docRef.update({'cart': cart});
    _loadCart();
  }

  double get totalPrice {
    double total = 0;
    for (var item in cartItems) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  double deliveryFee = 50;

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
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cartItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text(
                              'Корзина пуста',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: item['image'] != null &&
                                            item['image']
                                                .toString()
                                                .startsWith('http')
                                        ? Image.network(
                                            item['image'],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            item['image'] ?? '',
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          item['description'] ?? '',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          '${item['price']} р.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.add_circle,
                                            color: Colors.orange),
                                        onPressed: () async {
                                          await addToCart(item);
                                        },
                                      ),
                                      Text(
                                        '${item['quantity']}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.remove_circle,
                                            color: Colors.orange),
                                        onPressed: () async {
                                          if (item['quantity'] > 1) {
                                            final user = FirebaseAuth
                                                .instance.currentUser;
                                            if (user == null) return;
                                            final docRef = FirebaseFirestore
                                                .instance
                                                .collection('users')
                                                .doc(user.uid);
                                            final doc = await docRef.get();
                                            List cart =
                                                List<Map<String, dynamic>>.from(
                                                    doc['cart'] ?? []);
                                            final idx = cart.indexWhere((i) =>
                                                i['menuItemId'] ==
                                                item['menuItemId']);
                                            if (idx >= 0) {
                                              cart[idx]['quantity'] -= 1;
                                              await docRef
                                                  .update({'cart': cart});
                                              _loadCart();
                                            }
                                          } else {
                                            await removeFromCart(
                                                item['menuItemId']);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Цена:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${totalPrice.toStringAsFixed(2)} р.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Доставка:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${deliveryFee.toStringAsFixed(2)} р.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Итого:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(totalPrice + deliveryFee).toStringAsFixed(2)} р.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: cartItems.isEmpty
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Оплата успешно выполнена!')),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 100, vertical: 15),
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
    );
  }
}
