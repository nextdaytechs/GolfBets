import 'package:hive/hive.dart';

part 'skins_settings.g.dart';

@HiveType(typeId: 4)
class SkinsSettings extends HiveObject {
  @HiveField(0)
  List<String> selectedPlayers;

  @HiveField(1)
  bool carryOver;

  @HiveField(2)
  int basePoints;

  @HiveField(3)
  int birdieBonus;

  @HiveField(4)
  int eagleBonus;

  @HiveField(5)
  int albatrosBonus;

  SkinsSettings({
    this.selectedPlayers = const [],
    this.carryOver = false,
    this.basePoints = 1,
    this.birdieBonus = 2,
    this.eagleBonus = 4,
    this.albatrosBonus = 5,
  });
}