import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bajoland/main.dart';
import 'package:bajoland/data/bajo_locations.dart';
import 'package:bajoland/models/destinasi_model.dart';
import 'package:bajoland/screens/all_destinations_screen.dart';

void main() {
  // Mempastikan environment SharedPreferences dan widget Flutter siap digunakan.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Filter Pulau mengacu pada nama pulau juga, bukan kategori saja.
  test('Pulau category includes islands classified under other categories', () {
    const kelor = DestinasiModel(
      id: 9,
      name: 'Pulau Kelor',
      category: 'Trekking & Pantai',
      ticketPrice: 0,
      rating: 4.8,
      location: 'Labuan Bajo',
      description: '',
      imageUrl: '',
    );
    const dermaga = DestinasiModel(
      id: 7,
      name: 'Dermaga Kampung Ujung',
      category: 'Kuliner & Dermaga',
      ticketPrice: 0,
      rating: 4.7,
      location: 'Labuan Bajo',
      description: '',
      imageUrl: '',
    );

    expect(destinationMatchesCategory(kelor, 'Pulau'), isTrue);
    expect(destinationMatchesCategory(dermaga, 'Pulau'), isFalse);
  });

  // Pastikan lokasi diving/kuliner baru muncul di data yang dipakai filter peta.
  test('Diving and culinary filters show the right destinations', () {
    final divingNames = bajoDestinations
        .where(
          (destination) =>
              destination.category.toLowerCase().contains('diving'),
        )
        .map((destination) => destination.name);
    final culinaryNames = bajoDestinations
        .where(
          (destination) =>
              destination.category.toLowerCase().contains('kuliner'),
        )
        .map((destination) => destination.name);

    expect(divingNames, containsAll(['Manta Point', 'Batu Bolong']));
    expect(
      culinaryNames,
      containsAll([
        'Dermaga Kampung Ujung',
        'Taman Laut Handayani Seafood Restaurant',
      ]),
    );
  });

  // Preferensi login palsu menjaga widget test tidak membaca sesi perangkat nyata.
  testWidgets('BajoLand initial render test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'loginData': false});

    await tester.pumpWidget(
      const BajoLandApp(isLoggedIn: false, userName: 'Wisatawan'),
    );
    await tester.pump();

    expect(find.text('Masuk'), findsOneWidget);
  });
}
