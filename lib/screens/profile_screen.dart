import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_app/models/app_user.dart';

//TODO сделать сохранение информации в бд
//TODO сделать отмену редактирования данных
//TODO реализовать отдельный экран изменения данных
//TODO изменить поля для ввода в базу данных и отображение информации не через поля, а через текст

class ProfileScreen extends StatefulWidget {
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
                              backgroundImage: AssetImage(
                                  'assets/images/avatar_placeholder.png'),
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
                    ],
                  ),
                ),
    );
  }
}
