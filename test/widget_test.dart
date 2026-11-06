import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bajoland/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BajoLand initial render test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'loginData': false});

    await tester.pumpWidget(
      const BajoLandApp(
        isLoggedIn: false,
        userName: 'Wisatawan',
      ),
    );
    await tester.pump();

    expect(find.text('BajoLand'), findsWidgets);
    expect(find.text('Masuk ke BajoLand'), findsOneWidget);
  });
}
