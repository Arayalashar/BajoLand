// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItineraryItemAdapter extends TypeAdapter<ItineraryItem> {
  @override
  final int typeId = 0;

  @override
  ItineraryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItineraryItem(
      destination: fields[0] as String,
      activity: fields[1] as String,
      budget: fields[2] as double,
      scheduledDate: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ItineraryItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.destination)
      ..writeByte(1)
      ..write(obj.activity)
      ..writeByte(2)
      ..write(obj.budget)
      ..writeByte(3)
      ..write(obj.scheduledDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

