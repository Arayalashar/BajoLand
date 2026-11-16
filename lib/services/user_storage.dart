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
    final username = user.username.trim();
    final fullName = user.fullName.trim();
    if (username.isEmpty || fullName.isEmpty || user.password.isEmpty) {
      return false;
    }

    final normalizedUsername = username.toLowerCase();
    final existingUsers = await _loadUsers();
    final isDuplicate = UserModel.registeredUsers.any(
          (registeredUser) =>
              registeredUser.username.toLowerCase() == normalizedUsername,
        ) ||
        existingUsers.any(
          (registeredUser) =>
              registeredUser.username.toLowerCase() == normalizedUsername,
        );

    if (isDuplicate) return false;

    final prefs = await SharedPreferences.getInstance();
    existingUsers.add(
      UserModel(
        username: username,
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

  Future<UserModel?> authenticate(String username, String password) async {
    final demoUser = UserModel.authenticate(username, password);
    if (demoUser != null) return demoUser;

    for (final user in await _loadUsers()) {
      if (user.username.toLowerCase() == username.trim().toLowerCase() &&
          user.password == password) {
        return user;
      }
    }
    return null;
  }
}
