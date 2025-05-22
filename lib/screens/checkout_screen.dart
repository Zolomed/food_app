import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  List<Map<String, dynamic>> addresses = [];
  String? selectedAddressId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    nameController.text = data?['name'] ?? '';
    phoneController.text = data?['phone'] ?? '';
    final List addressesRaw = data?['addresses'] ?? [];
    setState(() {
      addresses = List<Map<String, dynamic>>.from(addressesRaw);
      selectedAddressId = data?['selectedAddressId'] ??
          (addresses.isNotEmpty ? addresses.first['id'] : null);
      isLoading = false;
    });
  }

  Future<void> _addAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressScreen()),
    );
    if (result == true) {
      await _loadUserData();
      setState(() {});
    }
  }

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'cart': []});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заказ оформлен!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Оплата заказа'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Имя для доставки
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Имя для доставки',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Введите имя' : null,
                    ),
                    SizedBox(height: 16),
                    // Телефон для доставки
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Телефон для доставки',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Введите телефон'
                          : null,
                    ),
                    SizedBox(height: 16),
                    // Список адресов + добавить адрес
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedAddressId,
                            items: [
                              ...addresses.map((address) =>
                                  DropdownMenuItem<String>(
                                    value: address['id'],
                                    child:
                                        Text(address['name'] ?? 'Без названия'),
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
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Адрес доставки',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (value) => value == null
                                ? 'Выберите адрес доставки'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitOrder,
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
            ),
    );
  }
}
