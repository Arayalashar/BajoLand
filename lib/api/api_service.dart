import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destinasi_model.dart';

/// Service REST API untuk Destinasi Wisata Labuan Bajo (Modul 5: HTTP Request & JSON Parsing)
class ApiService {
  /// URL Endpoint REST API publik di repository GitHub BajoLand
  static const String _baseUrl =
      'https://raw.githubusercontent.com/Arayalashar/BajoLand/main/assets/data';

  /// Mengambil seluruh daftar destinasi wisata Labuan Bajo via HTTP GET
  static Future<List<DestinasiModel>> getDestinasi() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/destinasi.json'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => DestinasiModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server merespons kode: ${response.statusCode}');
      }
    } catch (_) {
      // Fallback data lokal jika perangkat offline saat pengujian
      return _fallbackDestinasi;
    }
  }

  /// Mengambil detail satu destinasi berdasarkan ID
  static Future<DestinasiModel> getDestinasiDetail(int id) async {
    try {
      final list = await getDestinasi();
      return list.firstWhere(
        (item) => item.id == id,
        orElse: () => _fallbackDestinasi.firstWhere((e) => e.id == id),
      );
    } catch (_) {
      return _fallbackDestinasi.firstWhere(
        (item) => item.id == id,
        orElse: () => _fallbackDestinasi.first,
      );
    }
  }

  /// Data fallback siap saji (100% sinkron dengan bajo_locations.dart)
  static final List<DestinasiModel> _fallbackDestinasi = [
    const DestinasiModel(
      id: 1,
      name: 'Pulau Padar',
      category: 'Trekking & Panorama',
      ticketPrice: 150000.0,
      rating: 4.9,
      location: 'Kepulauan Komodo, Labuan Bajo',
      description:
          'Pemandangan spektakuler 3 teluk berpasir warna-warni yang ikonik dari atas bukit.',
      imageUrl:
          'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?auto=format&fit=crop&w=800&q=80',
    ),
    const DestinasiModel(
      id: 2,
      name: 'Pink Beach (Pantai Merah)',
      category: 'Pantai & Snorkeling',
      ticketPrice: 50000.0,
      rating: 4.8,
      location: 'Pulau Komodo, Labuan Bajo',
      description:
          'Pantai eksotis dengan pasir berwarna merah muda alami dan terumbu karang indah.',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    ),
    const DestinasiModel(
      id: 3,
      name: 'Pulau Komodo (Loh Liang)',
      category: 'Taman Nasional & Satwa',
      ticketPrice: 250000.0,
      rating: 4.9,
      location: 'Taman Nasional Komodo, NTT',
      description:
          'Habitat konservasi satwa purba Komodo Dragon di Taman Nasional Komodo.',
      imageUrl:
          'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=800&q=80',
    ),
    const DestinasiModel(
      id: 4,
      name: 'Manta Point',
      category: 'Diving & Snorkeling',
      ticketPrice: 100000.0,
      rating: 4.9,
      location: 'Selat Linta, Kepulauan Komodo',
      description:
          'Spot snorkeling berenang bersama kawanan pari manta raksasa di arus laut toska.',
      imageUrl:
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80',
    ),
    const DestinasiModel(
      id: 5,
      name: 'Goa Rangko',
      category: 'Gua & Kolam Alami',
      ticketPrice: 35000.0,
      rating: 4.7,
      location: 'Desa Rangko, Labuan Bajo',
      description:
          'Kolam air asin alami dalam gua stalaktit yang berkilau biru saat terkena sinar matahari.',
      imageUrl:
          'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800&q=80',
    ),
    const DestinasiModel(
      id: 6,
      name: 'Taka Makassar',
      category: 'Gusung Pasir & Laut',
      ticketPrice: 50000.0,
      rating: 4.8,
      location: 'Dekat Manta Point, Kepulauan Komodo',
      description:
          'Pulau pasir timbul berbentuk bulan sabit di tengah lautan toska luas nan jernih.',
      imageUrl:
          'https://images.unsplash.com/photo-1512100356356-de1b84283e18?auto=format&fit=crop&w=800&q=80',
    ),
    const DestinasiModel(
      id: 7,
      name: 'Dermaga Kampung Ujung',
      category: 'Kuliner & Dermaga',
      ticketPrice: 10000.0,
      rating: 4.7,
      location: 'Pusat Kota Labuan Bajo',
      description:
          'Pusat keberangkatan kapal phinisi dan pusat kuliner seafood segar Labuan Bajo.',
      imageUrl:
          'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=800&q=80',
    ),
    const DestinasiModel(
      id: 8,
      name: 'Bandara Komodo',
      category: 'Transportasi Udara',
      ticketPrice: 0.0,
      rating: 4.8,
      location: 'Jl. Bandara Komodo, Labuan Bajo',
      description:
          'Gerbang udara utama menuju keindahan Labuan Bajo dan Pulau Flores.',
      imageUrl:
          'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=800&q=80',
    ),
  ];
}
