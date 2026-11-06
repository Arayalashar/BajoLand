import 'package:hive/hive.dart';

part 'itinerary_item.g.dart';

/// Model Database Lokal Hive untuk Jadwal & Anggaran (Modul 3 & Modul 6: HiveObject)
@HiveType(typeId: 0)
class ItineraryItem extends HiveObject {
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

