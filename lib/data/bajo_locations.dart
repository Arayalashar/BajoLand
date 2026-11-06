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
    description: 'Pemandangan spektakuler 3 teluk berpasir warna-warni yang ikonik dari atas bukit.',
    latitude: -8.6536,
    longitude: 119.5700,
    ticketPrice: 150000.0,
    rating: 4.9,
    location: 'Kepulauan Komodo, Labuan Bajo',
    imageUrl: 'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 2,
    name: 'Pink Beach (Pantai Merah)',
    category: 'Pantai & Snorkeling',
    description: 'Pantai eksotis dengan pasir berwarna merah muda alami dan terumbu karang indah.',
    latitude: -8.6019,
    longitude: 119.5204,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Pulau Komodo, Labuan Bajo',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 3,
    name: 'Pulau Komodo (Loh Liang)',
    category: 'Taman Nasional & Satwa',
    description: 'Habitat konservasi satwa purba Komodo Dragon di Taman Nasional Komodo.',
    latitude: -8.5833,
    longitude: 119.4833,
    ticketPrice: 250000.0,
    rating: 4.9,
    location: 'Taman Nasional Komodo, NTT',
    imageUrl: 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 4,
    name: 'Manta Point',
    category: 'Diving & Snorkeling',
    description: 'Spot snorkeling berenang bersama kawanan pari manta raksasa di arus laut toska.',
    latitude: -8.5441,
    longitude: 119.6425,
    ticketPrice: 100000.0,
    rating: 4.9,
    location: 'Selat Linta, Kepulauan Komodo',
    imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 5,
    name: 'Goa Rangko',
    category: 'Gua & Kolam Alami',
    description: 'Kolam air asin alami dalam gua stalaktit yang berkilau biru saat terkena sinar matahari.',
    latitude: -8.4418,
    longitude: 119.8975,
    ticketPrice: 35000.0,
    rating: 4.7,
    location: 'Desa Rangko, Labuan Bajo',
    imageUrl: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 6,
    name: 'Taka Makassar',
    category: 'Gusung Pasir & Laut',
    description: 'Pulau pasir timbul berbentuk bulan sabit di tengah lautan toska luas nan jernih.',
    latitude: -8.5524,
    longitude: 119.5962,
    ticketPrice: 50000.0,
    rating: 4.8,
    location: 'Dekat Manta Point, Kepulauan Komodo',
    imageUrl: 'https://images.unsplash.com/photo-1512100356356-de1b84283e18?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 7,
    name: 'Dermaga Kampung Ujung',
    category: 'Kuliner & Dermaga',
    description: 'Pusat keberangkatan kapal phinisi dan pusat kuliner seafood segar Labuan Bajo.',
    latitude: -8.4892,
    longitude: 119.8805,
    ticketPrice: 10000.0,
    rating: 4.7,
    location: 'Pusat Kota Labuan Bajo',
    imageUrl: 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=800&q=80',
  ),
  LocationData(
    id: 8,
    name: 'Bandara Komodo',
    category: 'Transportasi Udara',
    description: 'Gerbang udara utama menuju keindahan Labuan Bajo dan Pulau Flores.',
    latitude: -8.5139,
    longitude: 119.8889,
    ticketPrice: 0.0,
    rating: 4.8,
    location: 'Jl. Bandara Komodo, Labuan Bajo',
    imageUrl: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=800&q=80',
  ),
];
