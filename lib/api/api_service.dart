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
          'Pulau Padar merupakan pulau ketiga terbesar di kawasan Taman Nasional Komodo yang terkenal dengan panorama puncaknya yang luar biasa spektakuler. Dari puncak bukit tertinggi, pengunjung dapat menyaksikan perpaduan dramatis tiga lekukan teluk alami dengan gradasi warna pasir berbeda, yaitu putih bersih, abu-abu arang, hingga rona merah muda yang memesona. Jalur pendakian telah dilengkapi anak tangga teratur yang aman, menjadikannya destinasi wajib untuk menikmati momen matahari terbit maupun senja terbaik di Labuan Bajo dengan latar lautan Flores yang megah.',
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
          'Pink Beach atau Pantai Merah adalah salah satu dari segelintir pantai di dunia yang memiliki pasir berwarna merah muda alami. Rona merah muda ini tercipta dari serpihan mikroorganisme foraminifera bersel tunggal merah yang bercampur sempurna dengan butiran pasir putih lembut. Dikelilingi bukit sabana hijau dan air laut toska yang sebening kristal, pantai ini merupakan surga snorkeling kelas dunia dengan terumbu karang warna-warni yang kaya serta beragam biota laut tropis yang hidup tepat beberapa meter dari bibir pantai.',
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
          'Loh Liang di Pulau Komodo adalah pintu gerbang utama penjelajahan alam liar untuk menyaksikan kadal purba terbesar di dunia, Varanus komodoensis, langsung di habitat aslinya. Ditemani oleh ranger atau jagawana berpengalaman, pengunjung akan diajak menyusuri hutan musim tropis, padang sabana luas, serta lembah teduh yang dihuni berbagai satwa eksotis lainnya seperti rusa timor, babi hutan, burung kakatua jambul kuning, dan elang Flores. Pengalaman trekking di kawasan situs warisan dunia UNESCO ini memberikan sensasi petualangan purbakala yang tiada duanya.',
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
          'Manta Point atau Karang Makassar adalah spot perairan terbuka legendaris di Selat Linta yang menjadi habitat pembersihan (cleaning station) sekaligus perburuan plankton bagi kawanan pari manta raksasa (Manta birostris). Di titik ini, wisatawan dan penyelam dapat berenang berdampingan secara aman dengan pari manta yang memiliki rentang sayap mencapai hingga 4-5 meter saat mereka meluncur anggun di kedalaman laut biru toska. Kejernihan air yang luar biasa dan hamparan karang bawah laut yang luas membuat pengalaman snorkeling dan diving di sini begitu magis dan tak terlupakan.',
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
          'Goa Rangko adalah destinasi tersembunyi yang unik di kawasan pesisir utara Labuan Bajo, menyajikan pesona kolam air asin alami di dalam rongga gua karst yang sunyi dan magis. Keistimewaan terbesar gua ini terjadi antara pukul 12.00 hingga 14.00 WITA, saat sinar matahari masuk menembus celah langit-langit gua dan menerangi air kolam hingga berkilau biru toska menyala. Pengunjung dapat berenang dan mengapung dengan rileks di air asin yang sejuk sambil mengagumi formasi bebatuan stalaktit dan stalagmit purba berukir indah yang menggantung di sekeliling dinding gua.',
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
          'Taka Makassar adalah atol atau gosong pasir timbul berbentuk melengkung menyerupai bulan sabit yang berada di tengah perairan dangkal laut Labuan Bajo. Pulau kecil tanpa vegetasi ini hanya muncul saat air laut surut dan dikelilingi oleh laguna berair dangkal dengan gradasi warna biru kehijauan yang sangat jernih. Kontras antara pasir putih halus dengan laut toska yang tenang menjadikannya lokasi favorit wisatawan untuk bersantai, berfoto estetik bergaya tropis, serta melakukan snorkeling ringan menjelajahi terumbu karang dangkal di sekeliling pulau.',
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
          'Dermaga Kampung Ujung adalah denyut nadi kehidupan maritim Labuan Bajo sekaligus destinasi wisata kuliner malam paling populer di pusat kota. Di sini bersandar jajaran kapal phinisi megah dan speedboat modern yang siap mengarungi perairan Komodo. Setiap petang hingga larut malam, area dermaga menjelma menjadi pasar kuliner tepi laut yang semarak, menyajikan aneka tangkapan hidangan laut segar seperti ikan kerapu bakar, cumi saus padang, lobster, dan udang bakar yang diolah langsung dengan cita rasa khas pesisir ditemani hembusan semilir angin laut malam Flores.',
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
          'Bandara Internasional Komodo merupakan gerbang masuk udara utama yang modern dan representatif bagi para pelancong dari seluruh nusantara maupun mancanegara menuju surga pariwisata Labuan Bajo dan kepulauan Flores. Arsitektur terminalnya mengusung sentuhan kultural modern yang terinspirasi dari keunikan sisik hewan purba komodo dan keanggunan kain tenun ikat Manggarai. Terletak sangat strategis dekat dengan jantung kota dan pelabuhan, bandara ini dilengkapi fasilitas pelayanan lengkap yang menyambut setiap tamu dengan kenyamanan dan keramahan khas Nusa Tenggara Timur.',
      imageUrl:
          'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=800&q=80',
    ),
  ];
}
