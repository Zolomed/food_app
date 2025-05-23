import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_app/models/app_user.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userData = AppUser.fromMap(doc.id, doc.data() ?? {});
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _showOrdersDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Мои заказы'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return Text('У вас нет заказов.');
              return ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (context, idx) {
                  final order = docs[idx].data();
                  final date = order['createdAt'] != null
                      ? (order['createdAt'] as Timestamp).toDate()
                      : DateTime.now();
                  final items = order['items'] as List<dynamic>? ?? [];
                  final total = order['total'] ?? 0;
                  final payment = order['paymentType'] ?? '';
                  final status = order['status'] ?? '';
                  final address = order['address'];
                  String addressText = '';
                  if (address != null) {
                    // Собираем полный адрес из полей
                    final city = address['city'] ?? '';
                    final street = address['street'] ?? '';
                    final house = address['house'] ?? '';
                    final flat = address['flat'] ?? '';
                    final entrance = address['entrance'] ?? '';
                    final floor = address['floor'] ?? '';
                    final comment = address['comment'] ?? '';
                    List<String> parts = [];
                    if (city.isNotEmpty) parts.add(city);
                    if (street.isNotEmpty) parts.add('ул. $street');
                    if (house.isNotEmpty) parts.add('д. $house');
                    if (flat.isNotEmpty) parts.add('кв. $flat');
                    if (entrance.isNotEmpty) parts.add('подъезд $entrance');
                    if (floor.isNotEmpty) parts.add('этаж $floor');
                    if (comment.isNotEmpty) parts.add('(${comment})');
                    addressText = parts.join(', ');
                  }
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                          'Заказ от ${DateFormat('dd.MM.yyyy HH:mm').format(date)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Статус: $status'),
                          Text(
                              'Оплата: ${payment == 'card' ? 'Картой при получении' : 'Наличными'}'),
                          Text('Сумма: ${total.toStringAsFixed(2)} ₽'),
                          if (addressText.isNotEmpty)
                            Text('Адрес: $addressText'),
                          Text(
                              'Блюда: ${items.map((i) => i['name']).join(', ')}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Профиль'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.orange),
            onPressed: () async {
              await Navigator.pushNamed(context, '/edit_profile');
              _loadUserData();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
              ? Center(child: Text('Ошибка загрузки профиля'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: userData!.photoUrl != null &&
                                      userData!.photoUrl!.isNotEmpty
                                  ? NetworkImage(userData!.photoUrl!)
                                  : AssetImage(
                                          'assets/images/avatar_placeholder.jpg')
                                      as ImageProvider,
                            ),
                            SizedBox(height: 10),
                            Text(
                              userData!.name,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text('Имя',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text(userData!.name, style: TextStyle(fontSize: 18)),
                      SizedBox(height: 20),
                      Text('E-mail',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text(userData!.email, style: TextStyle(fontSize: 18)),
                      SizedBox(height: 20),
                      Text('Телефон',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text(userData!.phone, style: TextStyle(fontSize: 18)),
                      SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _showOrdersDialog,
                          icon: Icon(Icons.receipt_long),
                          label: Text('Мои заказы'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
