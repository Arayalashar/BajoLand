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
    // Jika user memasukkan username selain di atas tetapi password tidak kosong,
    // izinkan login dengan nama sesuai username agar fleksibel saat testing
    if (username.trim().isNotEmpty && password.trim().isNotEmpty) {
      return UserModel(
        username: username.trim(),
        password: password,
        fullName: username.trim(),
      );
    }
    return null;
  }
}

