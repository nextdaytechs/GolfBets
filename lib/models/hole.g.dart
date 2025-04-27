// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hole.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HoleAdapter extends TypeAdapter<Hole> {
  @override
  final int typeId = 1;

  @override
  Hole read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hole(
      number: fields[0] as int,
      par: fields[1] as int,
      handicapRating: fields[2] as int,
      name: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Hole obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.par)
      ..writeByte(2)
      ..write(obj.handicapRating)
      ..writeByte(3)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
