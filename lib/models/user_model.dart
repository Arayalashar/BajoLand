/// Model User untuk autentikasi login (Modul 3: Model Class)
class UserModel {
  final String email;
  final String username;
  final String password;
  final String fullName;

  const UserModel({
    String? email,
    String? username,
    required this.password,
    required this.fullName,
  })  : email = email ?? username ?? '',
        username = username ?? email ?? '';

  Map<String, String> toJson() => {
    'email': email,
    'username': username,
    'password': password,
    'fullName': fullName,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final identifier = (json['email'] ?? json['username'] ?? '') as String;
    return UserModel(
      email: identifier,
      username: identifier,
      password: (json['password'] ?? '') as String,
      fullName: (json['fullName'] ?? '') as String,
    );
  }

  /// Daftar akun bawaan untuk reserved username pengujian praktikum
  static const List<UserModel> registeredUsers = [
    UserModel(
      username: 'arya',
      email: 'arya',
      password: '123',
      fullName: 'Arya Al Ashar',
    ),
    UserModel(
      username: 'wisatawan',
      email: 'wisatawan',
      password: '123',
      fullName: 'Wisatawan Bajo',
    ),
  ];

  /// Validasi kredensial login
  static UserModel? authenticate(String identifier, String password) {
    return null;
  }
}
