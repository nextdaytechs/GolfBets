// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nassau_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NassauSettingsAdapter extends TypeAdapter<NassauSettings> {
  @override
  final int typeId = 3;

  @override
  NassauSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NassauSettings(
      selectedPlayers: (fields[0] as List).cast<String>(),
      front9Bet: fields[1] as int,
      back9Bet: fields[2] as int,
      overallBet: fields[3] as int,
      handicaps: (fields[4] as Map).cast<String, int>(),
      skinsPoints: fields[5] as int,
      enableSkins: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NassauSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.selectedPlayers)
      ..writeByte(1)
      ..write(obj.front9Bet)
      ..writeByte(2)
      ..write(obj.back9Bet)
      ..writeByte(3)
      ..write(obj.overallBet)
      ..writeByte(4)
      ..write(obj.handicaps)
      ..writeByte(5)
      ..write(obj.skinsPoints)
      ..writeByte(6)
      ..write(obj.enableSkins);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NassauSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
