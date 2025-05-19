class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }
}
