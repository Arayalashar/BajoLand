/// Data akun pengguna; akun persisten dikelola oleh UserStorage.
class UserModel {
  // `email` dan `username` saling menjadi fallback agar formulir lama tetap kompatibel.
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
    // Data lama mungkin hanya menyimpan salah satu kunci: email atau username.
    final identifier = (json['email'] ?? json['username'] ?? '') as String;
    return UserModel(
      email: identifier,
      username: identifier,
      password: (json['password'] ?? '') as String,
      fullName: (json['fullName'] ?? '') as String,
    );
  }

  /// Akun demo yang juga dipakai UserStorage untuk menolak nama akun duplikat.
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

  /// Placeholder lama; verifikasi akun tersimpan dilakukan lewat UserStorage.authenticate.
  static UserModel? authenticate(String identifier, String password) {
    return null;
  }
}
