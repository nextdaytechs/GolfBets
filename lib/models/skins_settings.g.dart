// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skins_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SkinsSettingsAdapter extends TypeAdapter<SkinsSettings> {
  @override
  final int typeId = 4;

  @override
  SkinsSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SkinsSettings(
      selectedPlayers: (fields[0] as List).cast<String>(),
      carryOver: fields[1] as bool,
      basePoints: fields[2] as int,
      birdieBonus: fields[3] as int,
      eagleBonus: fields[4] as int,
      albatrosBonus: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SkinsSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.selectedPlayers)
      ..writeByte(1)
      ..write(obj.carryOver)
      ..writeByte(2)
      ..write(obj.basePoints)
      ..writeByte(3)
      ..write(obj.birdieBonus)
      ..writeByte(4)
      ..write(obj.eagleBonus)
      ..writeByte(5)
      ..write(obj.albatrosBonus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkinsSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
