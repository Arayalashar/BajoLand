/// Data peta untuk satu destinasi, termasuk koordinat yang dipakai Geolocator.
class LocationData {
  // Field jarak bersifat opsional karena jarak hanya tersedia setelah GPS diproses.
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

  /// Jarak yang sudah dihitung ditampilkan dalam meter (< 1 km) atau kilometer.
  String get formattedDistance {
    if (distanceInMeters == null) return 'Jarak belum dihitung';
    if (distanceInMeters! < 1000) {
      return '${distanceInMeters!.toStringAsFixed(0)} m';
    }
    final km = distanceInMeters! / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  /// Penanda dekat dipakai UI bila jarak hasil GPS kurang dari 500 meter.
  bool get isNear => distanceInMeters != null && distanceInMeters! < 500;
}

/// Sumber marker dan kartu Radar; ID/nama/kategori/media diselaraskan dengan katalog API.
final List<LocationData> bajoDestinations = [
  LocationData(
    id: 1,
    name: 'Pulau Padar',
    category: 'Trekking & Panorama',
    description: 'Pulau Padar merupakan pulau ketiga terbesar di kawasan Taman Nasional Komodo yang terkenal dengan panorama puncaknya yang luar biasa spektakuler. Dari puncak bukit tertinggi, pengunjung dapat menyaksikan perpaduan dramatis tiga lekukan teluk alami dengan gradasi warna pasir berbeda, yaitu putih bersih, abu-abu arang, hingga rona merah muda yang memesona. Jalur pendakian telah dilengkapi anak tangga teratur yang aman, menjadikannya destinasi wajib untuk menikmati momen matahari terbit maupun senja terbaik di Labuan Bajo dengan latar lautan Flores yang megah.',
    latitude: -8.6536,
    longitude: 119.5700,
    ticketPrice: 150000.0,
    rating: 4.9,
    location: 'Kepulauan Komodo, Labuan Bajo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/15/Eksotisme_Pulau_padar_Labuan_Bajo.jpg/960px-Eksotisme_Pulau_padar_Labuan_Bajo.jpg',
  ),
  LocationData(
    id: 2,
    name: 'Pink Beach (Pantai Merah)',
    category: 'Pantai & Snorkeling',
    description: 'Pink Beach atau Pantai Merah adalah salah satu dari segelintir pantai di dunia yang memiliki pasir berwarna merah muda alami. Rona merah muda ini tercipta dari serpihan mikroorganisme foraminifera bersel tunggal merah yang bercampur sempurna dengan butiran pasir putih lembut. Dikelilingi bukit sabana hijau dan air laut toska yang sebening kristal, pantai ini merupakan surga snorkeling kelas dunia dengan terumbu karang warna-warni yang kaya serta beragam biota laut tropis yang hidup tepat beberapa meter dari bibir pantai.',
    latitude: -8.6019,
    longitude: 119.5204,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Pulau Komodo, Labuan Bajo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Pink_Beach%2C_Padar_Island%2C_Komodo_National_Park%2C_Indonesia%2C_20250822_1108_2678.jpg/960px-Pink_Beach%2C_Padar_Island%2C_Komodo_National_Park%2C_Indonesia%2C_20250822_1108_2678.jpg',
  ),
  LocationData(
    id: 3,
    name: 'Pulau Komodo (Loh Liang)',
    category: 'Taman Nasional & Satwa',
    description: 'Loh Liang di Pulau Komodo adalah pintu gerbang utama penjelajahan alam liar untuk menyaksikan kadal purba terbesar di dunia, Varanus komodoensis, langsung di habitat aslinya. Ditemani oleh ranger atau jagawana berpengalaman, pengunjung akan diajak menyusuri hutan musim tropis, padang sabana luas, serta lembah teduh yang dihuni berbagai satwa eksotis lainnya seperti rusa timor, babi hutan, burung kakatua jambul kuning, dan elang Flores. Pengalaman trekking di kawasan situs warisan dunia UNESCO ini memberikan sensasi petualangan purbakala yang tiada duanya.',
    latitude: -8.5833,
    longitude: 119.4833,
    ticketPrice: 250000.0,
    rating: 4.9,
    location: 'Taman Nasional Komodo, NTT',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e8/Komodo_dragon_%28Varanus_komodoensis%29.jpg/960px-Komodo_dragon_%28Varanus_komodoensis%29.jpg',
  ),
  LocationData(
    id: 4,
    name: 'Manta Point',
    category: 'Diving & Snorkeling',
    description: 'Manta Point atau Karang Makassar adalah spot perairan terbuka legendaris di Selat Linta yang menjadi habitat pembersihan (cleaning station) sekaligus perburuan plankton bagi kawanan pari manta raksasa (Manta birostris). Di titik ini, wisatawan dan penyelam dapat berenang berdampingan secara aman dengan pari manta yang memiliki rentang sayap mencapai hingga 4-5 meter saat mereka meluncur anggun di kedalaman laut biru toska. Kejernihan air yang luar biasa dan hamparan karang bawah laut yang luas membuat pengalaman snorkeling dan diving di sini begitu magis dan tak terlupakan.',
    latitude: -8.5441,
    longitude: 119.6425,
    ticketPrice: 100000.0,
    rating: 4.9,
    location: 'Selat Linta, Kepulauan Komodo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/81/A_Flying_Manta_ray.jpg/960px-A_Flying_Manta_ray.jpg',
  ),
  LocationData(
    id: 5,
    name: 'Goa Rangko',
    category: 'Gua & Kolam Alami',
    description: 'Goa Rangko adalah destinasi tersembunyi yang unik di kawasan pesisir utara Labuan Bajo, menyajikan pesona kolam air asin alami di dalam rongga gua karst yang sunyi dan magis. Keistimewaan terbesar gua ini terjadi antara pukul 12.00 hingga 14.00 WITA, saat sinar matahari masuk menembus celah langit-langit gua dan menerangi air kolam hingga berkilau biru toska menyala. Pengunjung dapat berenang dan mengapung dengan rileks di air asin yang sejuk sambil mengagumi formasi bebatuan stalaktit dan stalagmit purba berukir indah yang menggantung di sekeliling dinding gua.',
    latitude: -8.4418,
    longitude: 119.8975,
    ticketPrice: 35000.0,
    rating: 4.7,
    location: 'Desa Rangko, Labuan Bajo',
    imageUrl: 'https://i.pinimg.com/originals/6f/f8/5f/6ff85f1f19b6ea5331c3ec2bd0d1468e.jpg',
  ),
  LocationData(
    id: 6,
    name: 'Taka Makassar',
    category: 'Gusung Pasir & Laut',
    description: 'Taka Makassar adalah atol atau gosong pasir timbul berbentuk melengkung menyerupai bulan sabit yang berada di tengah perairan dangkal laut Labuan Bajo. Pulau kecil tanpa vegetasi ini hanya muncul saat air laut surut dan dikelilingi oleh laguna berair dangkal dengan gradasi warna biru kehijauan yang sangat jernih. Kontras antara pasir putih halus dengan laut toska yang tenang menjadikannya lokasi favorit wisatawan untuk bersantai, berfoto estetik bergaya tropis, serta melakukan snorkeling ringan menjelajahi terumbu karang dangkal di sekeliling pulau.',
    latitude: -8.5524,
    longitude: 119.5962,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Dekat Manta Point, Kepulauan Komodo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/28/Beautiful_Taka_Makassar_Island.jpg/960px-Beautiful_Taka_Makassar_Island.jpg',
  ),
  LocationData(
    id: 7,
    name: 'Dermaga Kampung Ujung',
    category: 'Kuliner & Dermaga',
    description: 'Dermaga Kampung Ujung adalah denyut nadi kehidupan maritim Labuan Bajo sekaligus destinasi wisata kuliner malam paling populer di pusat kota. Di sini bersandar jajaran kapal phinisi megah dan speedboat modern yang siap mengarungi perairan Komodo. Setiap petang hingga larut malam, area dermaga menjelma menjadi pasar kuliner tepi laut yang semarak, menyajikan aneka tangkapan hidangan laut segar seperti ikan kerapu bakar, cumi saus padang, lobster, dan udang bakar yang diolah langsung dengan cita rasa khas pesisir ditemani hembusan semilir angin laut malam Flores.',
    latitude: -8.4892,
    longitude: 119.8805,
    ticketPrice: 10000.0,
    rating: 4.7,
    location: 'Pusat Kota Labuan Bajo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8f/Labuan_Bajo_Harbour.jpg/960px-Labuan_Bajo_Harbour.jpg',
  ),
  LocationData(
    id: 8,
    name: 'Bandara Komodo',
    category: 'Transportasi Udara',
    description: 'Bandara Internasional Komodo merupakan gerbang masuk udara utama yang modern dan representatif bagi para pelancong dari seluruh nusantara maupun mancanegara menuju surga pariwisata Labuan Bajo dan kepulauan Flores. Arsitektur terminalnya mengusung sentuhan kultural modern yang terinspirasi dari keunikan sisik hewan purba komodo dan keanggunan kain tenun ikat Manggarai. Terletak sangat strategis dekat dengan jantung kota dan pelabuhan, bandara ini dilengkapi fasilitas pelayanan lengkap yang menyambut setiap tamu dengan kenyamanan dan keramahan khas Nusa Tenggara Timur.',
    latitude: -8.5139,
    longitude: 119.8889,
    ticketPrice: 0.0,
    rating: 4.8,
    location: 'Jl. Bandara Komodo, Labuan Bajo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/da/KomodoAirport1.png/960px-KomodoAirport1.png',
  ),
  LocationData(
    id: 9,
    name: 'Pulau Kelor',
    category: 'Trekking & Pantai',
    description: 'Pulau Kelor adalah pulau kecil di dekat Labuan Bajo yang terkenal dengan jalur trekking singkat menuju puncak bukitnya. Dari atas, pengunjung dapat menikmati panorama laut Flores dan pulau-pulau di sekitarnya. Pantainya yang berpasir putih dan airnya yang jernih juga cocok untuk berenang serta snorkeling.',
    latitude: -8.4808,
    longitude: 119.5834,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Kepulauan Komodo, Labuan Bajo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fc/Sea_View_from_Kelor_Island_-_Pulau_Kelor%2C_Labuan_Bajo.jpg/960px-Sea_View_from_Kelor_Island_-_Pulau_Kelor%2C_Labuan_Bajo.jpg',
  ),
  LocationData(
    id: 10,
    name: 'Pulau Kanawa',
    category: 'Pantai & Snorkeling',
    description: 'Pulau Kanawa berada di perairan Flores, tidak jauh dari Labuan Bajo. Pulau ini menawarkan pantai berpasir putih, air laut yang jernih, dan terumbu karang yang dapat dijelajahi dengan snorkeling. Bukit kecil di pulau ini juga menjadi tempat untuk melihat panorama laut dan matahari terbit.',
    latitude: -8.4933,
    longitude: 119.7586,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Kepulauan Komodo, Labuan Bajo',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/68/Pulau_Kanawa%2C_Flores%2C_NTT.jpg',
  ),
  LocationData(
    id: 11,
    name: 'Gili Lawa Darat',
    category: 'Trekking & Panorama',
    description: 'Gili Lawa Darat terletak di utara Pulau Komodo dan dikenal dengan perbukitan sabana yang menghadap ke laut. Pendakian menuju puncak menyuguhkan pemandangan gugusan pulau dan perairan Taman Nasional Komodo, terutama saat matahari terbit atau terbenam.',
    latitude: -8.472778,
    longitude: 119.559722,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Taman Nasional Komodo, NTT',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c0/Sunrise_at_Gili_Lawa_Darat_Island.jpg/960px-Sunrise_at_Gili_Lawa_Darat_Island.jpg',
  ),
  LocationData(
    id: 12,
    name: 'Goa Batu Cermin',
    category: 'Gua & Geologi',
    description: 'Goa Batu Cermin adalah gua batu kapur dekat pusat Labuan Bajo. Ketika sinar matahari masuk melalui celah gua dan mengenai dinding batu yang mengandung mineral, pantulannya tampak seperti cermin. Pengunjung dapat menjelajahi lorong dan formasi batuan dengan pemandu lokal.',
    latitude: -8.47924,
    longitude: 119.898752,
    ticketPrice: 50000.0,
    rating: 4.7,
    location: 'Batu Cermin, Labuan Bajo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/44/Mirror_Stone_Cave%2C_Flores%2C_Indonesia%2C_20250827_0928_3845.jpg/960px-Mirror_Stone_Cave%2C_Flores%2C_Indonesia%2C_20250827_0928_3845.jpg',
  ),
  LocationData(
    id: 13,
    name: 'Pulau Rinca (Loh Buaya)',
    category: 'Taman Nasional & Satwa',
    description: 'Pulau Rinca merupakan bagian dari Taman Nasional Komodo. Dari kawasan Loh Buaya, pengunjung dapat mengikuti trekking bersama ranger untuk mengamati komodo dan bentang sabana pulau ini. Ikuti arahan ranger dan jaga jarak aman selama berada di habitat satwa liar.',
    latitude: -8.70,
    longitude: 119.68,
    ticketPrice: 150000.0,
    rating: 4.8,
    location: 'Taman Nasional Komodo, NTT',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7d/Hewan_Komodo_di_Pulau_Rinca_sebuah_pulau_kecil_dekat_Pulau_Komodo%2C_Nusa_Tenggara_Timur%2C_Indonesia._Di_pulau_ini_hidup_berbagai_jenis_binatang_seperti_komodo%2C_babi_liar%2C_kerbau_dan_burung.jpg/960px-thumbnail.jpg',
  ),
  LocationData(
    id: 14,
    name: 'Batu Bolong',
    category: 'Diving & Snorkeling',
    description: 'Batu Bolong adalah puncak karang di Taman Nasional Komodo yang menjadi salah satu lokasi menyelam terkenal. Terumbu karangnya menjadi habitat beragam ikan tropis dan penyu; arus dapat berubah, sehingga penyelaman sebaiknya dilakukan bersama operator dan pemandu berpengalaman.',
    latitude: -8.5458,
    longitude: 119.6350,
    ticketPrice: 100000.0,
    rating: 4.9,
    location: 'Selat Linta, Taman Nasional Komodo',
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3d/Green_sea_turtle_at_Batu_Bolong.JPG/960px-Green_sea_turtle_at_Batu_Bolong.JPG',
  ),
  LocationData(
    id: 15,
    name: 'Taman Laut Handayani Seafood Restaurant',
    category: 'Kuliner & Seafood',
    description: 'Taman Laut Handayani Seafood Restaurant adalah restoran seafood di tepi laut Labuan Bajo. Menu yang ditawarkan mencakup ikan bakar, udang, kepiting, dan hidangan laut lainnya dengan suasana makan terbuka dekat pelabuhan.',
    latitude: -8.492004,
    longitude: 119.8785031,
    ticketPrice: 0.0,
    rating: 4.5,
    location: 'Jl. Ir. Soekarno Hatta No. 9, Labuan Bajo',
    imageUrl: 'https://lh3.googleusercontent.com/grass-cs/AABkmLcoQcxnmIrID1b1SP17XAXFEqu2Gu9jMVLTXd-ptKRKMuTptCkV7hh5pllv_GTSE6gBsw3IfkGCaNHN-10aiIPpjrPuwuG-qebHT8pnO_PVFtM-kc85Mx-RPgdaH-wDZ9kQ4gyc=s1360-w1360-h1020-rw',
  ),
];
