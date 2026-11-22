import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Penyimpanan akun lokal menggunakan SharedPreferences (Modul 6).
class UserStorage {
  static const String _usersKey = 'registeredUsers';

  Future<List<UserModel>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedUsers = prefs.getStringList(_usersKey) ?? [];
    return encodedUsers
        .map(
          (encodedUser) => UserModel.fromJson(
            jsonDecode(encodedUser) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<bool> register(UserModel user) async {
    final account = (user.email.isNotEmpty ? user.email : user.username).trim();
    final fullName = user.fullName.trim();
    if (account.isEmpty || fullName.isEmpty || user.password.isEmpty) {
      return false;
    }

    final normalized = account.toLowerCase();
    final existingUsers = await _loadUsers();
    final isDuplicate = UserModel.registeredUsers.any(
          (registeredUser) =>
              registeredUser.username.toLowerCase() == normalized ||
              registeredUser.email.toLowerCase() == normalized,
        ) ||
        existingUsers.any(
          (registeredUser) =>
              registeredUser.username.toLowerCase() == normalized ||
              registeredUser.email.toLowerCase() == normalized,
        );

    if (isDuplicate) return false;

    final prefs = await SharedPreferences.getInstance();
    existingUsers.add(
      UserModel(
        email: account,
        username: account,
        password: user.password,
        fullName: fullName,
      ),
    );
    await prefs.setStringList(
      _usersKey,
      existingUsers
          .map((registeredUser) => jsonEncode(registeredUser.toJson()))
          .toList(),
    );
    return true;
  }

  Future<UserModel?> authenticate(String identifier, String password) async {
    final clean = identifier.trim().toLowerCase();
    for (final user in await _loadUsers()) {
      if ((user.email.toLowerCase() == clean ||
              user.username.toLowerCase() == clean) &&
          user.password == password) {
        return user;
      }
    }
    return null;
  }

  /// Mencari data akun pengguna berdasarkan nama lengkap terdaftar
  Future<UserModel?> findByFullName(String fullName) async {
    final clean = fullName.trim().toLowerCase();
    for (final user in await _loadUsers()) {
      if (user.fullName.trim().toLowerCase() == clean) {
        return user;
      }
    }
    return null;
  }

  /// Mengambil data pengguna yang terakhir kali terdaftar
  Future<UserModel?> getLastRegisteredUser() async {
    final users = await _loadUsers();
    if (users.isNotEmpty) {
      return users.last;
    }
    return null;
  }
}
