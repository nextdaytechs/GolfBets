import 'package:hive/hive.dart';

part 'nassau_settings.g.dart';

@HiveType(typeId: 3)
class NassauSettings extends HiveObject {
  @HiveField(0)
  List<String> selectedPlayers;

  @HiveField(1)
  int front9Bet;

  @HiveField(2)
  int back9Bet;

  @HiveField(3)
  int overallBet;

  @HiveField(4)
  Map<String, int> handicaps;

  @HiveField(5)
  int skinsPoints;

  @HiveField(6)
  bool enableSkins; // New field to enable/disable Skins

  NassauSettings({
    required this.selectedPlayers,
    required this.front9Bet,
    required this.back9Bet,
    required this.overallBet,
    required this.handicaps,
    this.skinsPoints = 1,
    this.enableSkins = false, // Default to disabled
  });
}