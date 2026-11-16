/// Model User untuk autentikasi login (Modul 3: Model Class)
class UserModel {
  final String username;
  final String password;
  final String fullName;

  const UserModel({
    required this.username,
    required this.password,
    required this.fullName,
  });

  Map<String, String> toJson() => {
    'username': username,
    'password': password,
    'fullName': fullName,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String,
    );
  }

  /// Daftar akun terdaftar default untuk pengujian praktikum
  static const List<UserModel> registeredUsers = [
    UserModel(
      username: 'arya',
      password: '123',
      fullName: 'Arya Al Ashar',
    ),
    UserModel(
      username: 'wisatawan',
      password: '123',
      fullName: 'Wisatawan Bajo',
    ),
    UserModel(
      username: 'admin',
      password: 'admin',
      fullName: 'Administrator BajoLand',
    ),
  ];

  /// Validasi kredensial login
  static UserModel? authenticate(String username, String password) {
    for (final user in registeredUsers) {
      if (user.username.trim().toLowerCase() == username.trim().toLowerCase() &&
          user.password == password) {
        return user;
      }
    }
    return null;
  }
}

