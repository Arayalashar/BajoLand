/// Model Data Lokasi & Konstanta Koordinat Labuan Bajo (Modul 3 & Modul 7)
class LocationData {
  final int id;
  final String name;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final double ticketPrice;
  final double rating;
  final String location;
  final String imageUrl;
  double? distanceInMeters;

  LocationData({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.ticketPrice,
    required this.rating,
    required this.location,
    required this.imageUrl,
    this.distanceInMeters,
  });

  /// Format jarak dalam kilometer atau meter yang rapi
  String get formattedDistance {
    if (distanceInMeters == null) return 'Jarak belum dihitung';
    if (distanceInMeters! < 1000) {
      return '${distanceInMeters!.toStringAsFixed(0)} m';
    }
    final km = distanceInMeters! / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  /// Menandai apakah lokasi berada dekat (< 500 meter)
  bool get isNear => distanceInMeters != null && distanceInMeters! < 500;
}

/// Daftar 8 Destinasi Lengkap Labuan Bajo (Sinkron 100% dengan Katalog API)
final List<LocationData> bajoDestinations = [
  LocationData(
    id: 1,
    name: 'Pulau Padar',
    category: 'Trekking & Panorama',
    description:
        'Pulau Padar merupakan pulau ketiga terbesar di kawasan Taman Nasional Komodo yang terkenal dengan panorama puncaknya yang luar biasa spektakuler. Dari puncak bukit tertinggi, pengunjung dapat menyaksikan perpaduan dramatis tiga lekukan teluk alami dengan gradasi warna pasir berbeda, yaitu putih bersih, abu-abu arang, hingga rona merah muda yang memesona. Jalur pendakian telah dilengkapi anak tangga teratur yang aman, menjadikannya destinasi wajib untuk menikmati momen matahari terbit maupun senja terbaik di Labuan Bajo dengan latar lautan Flores yang megah.',
    latitude: -8.6536,
    longitude: 119.5700,
    ticketPrice: 150000.0,
    rating: 4.9,
    location: 'Kepulauan Komodo, Labuan Bajo',
    imageUrl:
        'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 2,
    name: 'Pink Beach (Pantai Merah)',
    category: 'Pantai & Snorkeling',
    description:
        'Pink Beach atau Pantai Merah adalah salah satu dari segelintir pantai di dunia yang memiliki pasir berwarna merah muda alami. Rona merah muda ini tercipta dari serpihan mikroorganisme foraminifera bersel tunggal merah yang bercampur sempurna dengan butiran pasir putih lembut. Dikelilingi bukit sabana hijau dan air laut toska yang sebening kristal, pantai ini merupakan surga snorkeling kelas dunia dengan terumbu karang warna-warni yang kaya serta beragam biota laut tropis yang hidup tepat beberapa meter dari bibir pantai.',
    latitude: -8.6019,
    longitude: 119.5204,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Pulau Komodo, Labuan Bajo',
    imageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 3,
    name: 'Pulau Komodo (Loh Liang)',
    category: 'Taman Nasional & Satwa',
    description:
        'Loh Liang di Pulau Komodo adalah pintu gerbang utama penjelajahan alam liar untuk menyaksikan kadal purba terbesar di dunia, Varanus komodoensis, langsung di habitat aslinya. Ditemani oleh ranger atau jagawana berpengalaman, pengunjung akan diajak menyusuri hutan musim tropis, padang sabana luas, serta lembah teduh yang dihuni berbagai satwa eksotis lainnya seperti rusa timor, babi hutan, burung kakatua jambul kuning, dan elang Flores. Pengalaman trekking di kawasan situs warisan dunia UNESCO ini memberikan sensasi petualangan purbakala yang tiada duanya.',
    latitude: -8.5833,
    longitude: 119.4833,
    ticketPrice: 250000.0,
    rating: 4.9,
    location: 'Taman Nasional Komodo, NTT',
    imageUrl:
        'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 4,
    name: 'Manta Point',
    category: 'Diving & Snorkeling',
    description:
        'Manta Point atau Karang Makassar adalah spot perairan terbuka legendaris di Selat Linta yang menjadi habitat pembersihan (cleaning station) sekaligus perburuan plankton bagi kawanan pari manta raksasa (Manta birostris). Di titik ini, wisatawan dan penyelam dapat berenang berdampingan secara aman dengan pari manta yang memiliki rentang sayap mencapai hingga 4-5 meter saat mereka meluncur anggun di kedalaman laut biru toska. Kejernihan air yang luar biasa dan hamparan karang bawah laut yang luas membuat pengalaman snorkeling dan diving di sini begitu magis dan tak terlupakan.',
    latitude: -8.5441,
    longitude: 119.6425,
    ticketPrice: 100000.0,
    rating: 4.9,
    location: 'Selat Linta, Kepulauan Komodo',
    imageUrl:
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 5,
    name: 'Goa Rangko',
    category: 'Gua & Kolam Alami',
    description:
        'Goa Rangko adalah destinasi tersembunyi yang unik di kawasan pesisir utara Labuan Bajo, menyajikan pesona kolam air asin alami di dalam rongga gua karst yang sunyi dan magis. Keistimewaan terbesar gua ini terjadi antara pukul 12.00 hingga 14.00 WITA, saat sinar matahari masuk menembus celah langit-langit gua dan menerangi air kolam hingga berkilau biru toska menyala. Pengunjung dapat berenang dan mengapung dengan rileks di air asin yang sejuk sambil mengagumi formasi bebatuan stalaktit dan stalagmit purba berukir indah yang menggantung di sekeliling dinding gua.',
    latitude: -8.4418,
    longitude: 119.8975,
    ticketPrice: 35000.0,
    rating: 4.7,
    location: 'Desa Rangko, Labuan Bajo',
    imageUrl:
        'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 6,
    name: 'Taka Makassar',
    category: 'Gusung Pasir & Laut',
    description:
        'Taka Makassar adalah atol atau gosong pasir timbul berbentuk melengkung menyerupai bulan sabit yang berada di tengah perairan dangkal laut Labuan Bajo. Pulau kecil tanpa vegetasi ini hanya muncul saat air laut surut dan dikelilingi oleh laguna berair dangkal dengan gradasi warna biru kehijauan yang sangat jernih. Kontras antara pasir putih halus dengan laut toska yang tenang menjadikannya lokasi favorit wisatawan untuk bersantai, berfoto estetik bergaya tropis, serta melakukan snorkeling ringan menjelajahi terumbu karang dangkal di sekeliling pulau.',
    latitude: -8.5524,
    longitude: 119.5962,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Dekat Manta Point, Kepulauan Komodo',
    imageUrl:
        'https://images.unsplash.com/photo-1512100356356-de1b84283e18?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 7,
    name: 'Dermaga Kampung Ujung',
    category: 'Kuliner & Dermaga',
    description:
        'Dermaga Kampung Ujung adalah denyut nadi kehidupan maritim Labuan Bajo sekaligus destinasi wisata kuliner malam paling populer di pusat kota. Di sini bersandar jajaran kapal phinisi megah dan speedboat modern yang siap mengarungi perairan Komodo. Setiap petang hingga larut malam, area dermaga menjelma menjadi pasar kuliner tepi laut yang semarak, menyajikan aneka tangkapan hidangan laut segar seperti ikan kerapu bakar, cumi saus padang, lobster, dan udang bakar yang diolah langsung dengan cita rasa khas pesisir ditemani hembusan semilir angin laut malam Flores.',
    latitude: -8.4892,
    longitude: 119.8805,
    ticketPrice: 10000.0,
    rating: 4.7,
    location: 'Pusat Kota Labuan Bajo',
    imageUrl:
        'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 8,
    name: 'Bandara Komodo',
    category: 'Transportasi Udara',
    description:
        'Bandara Internasional Komodo merupakan gerbang masuk udara utama yang modern dan representatif bagi para pelancong dari seluruh nusantara maupun mancanegara menuju surga pariwisata Labuan Bajo dan kepulauan Flores. Arsitektur terminalnya mengusung sentuhan kultural modern yang terinspirasi dari keunikan sisik hewan purba komodo dan keanggunan kain tenun ikat Manggarai. Terletak sangat strategis dekat dengan jantung kota dan pelabuhan, bandara ini dilengkapi fasilitas pelayanan lengkap yang menyambut setiap tamu dengan kenyamanan dan keramahan khas Nusa Tenggara Timur.',
    latitude: -8.5139,
    longitude: 119.8889,
    ticketPrice: 0.0,
    rating: 4.8,
    location: 'Jl. Bandara Komodo, Labuan Bajo',
    imageUrl:
        'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=800&q=80',
  ),
];
