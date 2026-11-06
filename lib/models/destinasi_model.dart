/// Model Data Destinasi Wisata Labuan Bajo (Modul 3 & Modul 5: Model Class + factory fromJson)
class DestinasiModel {
  final int id;
  final String name;
  final String category;
  final double ticketPrice;
  final double rating;
  final String location;
  final String description;
  final String imageUrl;

  const DestinasiModel({
    required this.id,
    required this.name,
    required this.category,
    required this.ticketPrice,
    required this.rating,
    required this.location,
    required this.description,
    required this.imageUrl,
  });

  factory DestinasiModel.fromJson(Map<String, dynamic> json) {
    return DestinasiModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? 'Destinasi Labuan Bajo',
      category: json['category']?.toString() ?? 'Wisata Alam',
      ticketPrice: json['ticketPrice'] != null
          ? (json['ticketPrice'] as num).toDouble()
          : 0.0,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : 4.8,
      location: json['location']?.toString() ?? 'Labuan Bajo, NTT',
      description: json['description']?.toString() ?? 'Deskripsi keindahan destinasi wisata.',
      imageUrl: json['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?auto=format&fit=crop&w=800&q=80',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'ticketPrice': ticketPrice,
      'rating': rating,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}

