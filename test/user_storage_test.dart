import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bajoland/models/user_model.dart';
import 'package:bajoland/services/user_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('registered users persist and can authenticate', () async {
    final storage = UserStorage();
    const user = UserModel(
      username: 'jalanjalan',
      password: 'rahasia123',
      fullName: 'Nama Pengguna',
    );

    expect(await storage.register(user), isTrue);
    expect(
      (await UserStorage().authenticate('jalanjalan', 'rahasia123'))?.fullName,
      'Nama Pengguna',
    );
    expect(await storage.authenticate('jalanjalan', 'salah'), isNull);
  });

  test('registration rejects duplicate usernames case-insensitively', () async {
    final storage = UserStorage();

    expect(
      await storage.register(
        const UserModel(
          username: 'jalanjalan',
          password: 'rahasia123',
          fullName: 'Nama Pengguna',
        ),
      ),
      isTrue,
    );
    expect(
      await storage.register(
        const UserModel(
          username: 'JALANJALAN',
          password: 'rahasia123',
          fullName: 'Nama Lain',
        ),
      ),
      isFalse,
    );
    expect(
      await storage.register(
        const UserModel(
          username: 'arya',
          password: 'rahasia123',
          fullName: 'Nama Baru',
        ),
      ),
      isFalse,
    );
    expect(
      await storage.register(
        const UserModel(
          username: 'Wisatawan',
          password: 'rahasia123',
          fullName: 'Nama Baru',
        ),
      ),
      isFalse,
    );
  });

  test('registration rejects empty account fields', () async {
    final storage = UserStorage();

    expect(
      await storage.register(
        const UserModel(
          username: '  ',
          password: 'rahasia123',
          fullName: 'Nama',
        ),
      ),
      isFalse,
    );
  });
}
