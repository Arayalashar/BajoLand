import 'package:hive/hive.dart';

part 'itinerary_item.g.dart';

/// Satu agenda perjalanan yang disimpan permanen di box Hive `itineraries`.
@HiveType(typeId: 0)
class ItineraryItem extends HiveObject {
  // Nomor HiveField adalah kunci penyimpanan; jangan ubah nomor data yang sudah ada.
  @HiveField(0)
  String destination;

  @HiveField(1)
  String activity;

  @HiveField(2)
  double budget;

  @HiveField(3)
  DateTime scheduledDate;

  ItineraryItem({
    required this.destination,
    required this.activity,
    required this.budget,
    required this.scheduledDate,
  });
}

